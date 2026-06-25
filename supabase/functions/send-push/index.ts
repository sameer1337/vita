// Sends a push notification to every registered device via FCM HTTP v1.
//
// Auth: callers must send `x-admin-secret: <PUSH_ADMIN_SECRET>` (the admin
// panel does this from its server side). Secrets used (Supabase function env):
//   FCM_SERVICE_ACCOUNT     — the Firebase service-account JSON (string)
//   PUSH_ADMIN_SECRET       — shared secret gating this endpoint
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY — auto-provided by Supabase

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri: string;
  project_id: string;
}

function b64url(input: string): string {
  return btoa(input).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function b64urlBytes(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return b64url(s);
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

/// Exchange the service-account key for an OAuth access token scoped to FCM.
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claim))}`;
  const key = await importPrivateKey(sa.private_key);
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64urlBytes(new Uint8Array(sig))}`;

  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`OAuth token error: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Gate the endpoint.
  const adminSecret = Deno.env.get("PUSH_ADMIN_SECRET");
  if (!adminSecret || req.headers.get("x-admin-secret") !== adminSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  try {
    const { title, body, data } = await req.json();
    if (!title || !body) {
      return json({ error: "title and body are required" }, 400);
    }

    const sa = JSON.parse(
      Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}",
    ) as ServiceAccount;
    if (!sa.client_email) {
      return json({ error: "FCM_SERVICE_ACCOUNT not configured" }, 500);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // All device tokens.
    const tokensRes = await fetch(
      `${supabaseUrl}/rest/v1/device_tokens?select=token`,
      { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } },
    );
    const rows = (await tokensRes.json()) as { token: string }[];
    const tokens = rows.map((r) => r.token).filter(Boolean);

    if (tokens.length === 0) {
      return json({ sent: 0, failed: 0, total: 0, note: "No devices registered" });
    }

    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    let sent = 0;
    let failed = 0;
    const invalid: string[] = [];

    await Promise.all(
      tokens.map(async (token) => {
        const message: Record<string, unknown> = {
          token,
          notification: { title, body },
        };
        if (data && typeof data === "object") message.data = data;

        const r = await fetch(endpoint, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ message }),
        });
        if (r.ok) {
          sent++;
        } else {
          failed++;
          const errText = await r.text();
          // Prune tokens FCM no longer recognises.
          if (r.status === 404 || /UNREGISTERED|INVALID_ARGUMENT/.test(errText)) {
            invalid.push(token);
          }
        }
      }),
    );

    if (invalid.length > 0) {
      const list = invalid.map((t) => `"${t}"`).join(",");
      await fetch(
        `${supabaseUrl}/rest/v1/device_tokens?token=in.(${list})`,
        {
          method: "DELETE",
          headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
        },
      );
    }

    return json({ sent, failed, total: tokens.length, pruned: invalid.length });
  } catch (error) {
    console.error("send-push error:", error);
    return json(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
