import { encodeBase64 } from "jsr:@std/encoding@^1/base64";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const HOST = "exercisedb.p.rapidapi.com";

// Words that carry no matching signal.
const STOP = new Set(
  "the a an with on to of and or your for from down up ups out into at by"
    .split(" "),
);

const EQUIP_PREFIX =
  /^(dumbbell|barbell|cable|machine|smith|kettlebell|band|resistance band|bodyweight|weighted|assisted)\s+/;

/// Normalize a name: drop "(...)", punctuation/hyphens, collapse whitespace.
function clean(s: string): string {
  return s
    .toLowerCase()
    .replace(/\([^)]*\)/g, " ")
    .replace(/[^a-z0-9\s-]/g, " ")
    .replace(/-/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/// Strip simple trailing plurals ("ups" -> "up", "dips" -> "dip").
function depluralize(s: string): string {
  return s
    .split(" ")
    .map((w) => (w.length > 2 && w.endsWith("s") ? w.slice(0, -1) : w))
    .join(" ")
    .trim();
}

function significantWords(cleaned: string): string[] {
  return cleaned.split(" ").filter((w) => w.length > 1 && !STOP.has(w));
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders,
    });
  }

  const apiKey = Deno.env.get("EXERCISEDB_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "EXERCISEDB_API_KEY not configured" }),
      { status: 500, headers: corsHeaders },
    );
  }

  try {
    const body = await req.json();
    const rawName = (body.name as string | undefined)?.trim();
    const resolution = (body.resolution as string | undefined) ?? "360";
    if (!rawName) {
      return new Response(JSON.stringify({ error: "Missing name" }), {
        status: 400,
        headers: corsHeaders,
      });
    }

    const headers = { "x-rapidapi-host": HOST, "x-rapidapi-key": apiKey };

    const cleaned = depluralize(clean(rawName));
    const sig = significantWords(cleaned);
    // Require at least half of the meaningful words to match (min 1).
    const needed = sig.length === 0 ? 0 : Math.max(1, Math.ceil(sig.length / 2));
    const wantsBodyweight = !EQUIP_PREFIX.test(cleaned);

    // Queries to try, broad-to-narrow. We then filter results by word overlap,
    // so even a loose single-word search yields a precise pick.
    const queries = [
      cleaned,
      cleaned.replace(EQUIP_PREFIX, "").trim(),
      sig.join(" "),
      ...sig,
    ].filter((q, i, a) => q.length >= 2 && a.indexOf(q) === i);

    // deno-lint-ignore no-explicit-any
    let best: any = null;
    let bestScore = -1;

    for (const q of queries) {
      const res = await fetch(
        `https://${HOST}/exercises/name/${encodeURIComponent(q)}?limit=50`,
        { headers },
      );
      if (!res.ok) continue;
      const list = await res.json();
      if (!Array.isArray(list)) continue;

      for (const e of list) {
        const en = clean((e.name ?? "").toString());
        const eq = (e.equipment ?? "").toString().toLowerCase();
        const shared = sig.filter((w) => en.includes(w)).length;
        if (shared < needed) continue;

        // Rank: exact name > ends-with phrase > contains phrase > overlap;
        // prefer body-weight variants when no equipment was requested; prefer
        // the simplest (shortest) name.
        let score = shared * 1000;
        if (en === cleaned) {
          score += 100000;
        } else if (en.endsWith(cleaned)) {
          score += 30000;
        } else if (en.includes(cleaned)) {
          score += 10000;
        }
        if (wantsBodyweight && eq === "body weight") score += 4000;
        score -= en.length;

        if (score > bestScore) {
          bestScore = score;
          best = e;
        }
      }
      if (best) break; // accept the first query that produced a qualifying match
    }

    if (!best) {
      return new Response(JSON.stringify({ found: false }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    const imgRes = await fetch(
      `https://${HOST}/image?exerciseId=${best.id}&resolution=${resolution}`,
      { headers },
    );
    if (!imgRes.ok) {
      return new Response(JSON.stringify({ found: false }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    const bytes = new Uint8Array(await imgRes.arrayBuffer());
    const image = encodeBase64(bytes);

    return new Response(
      JSON.stringify({
        found: true,
        id: best.id,
        name: best.name,
        target: best.target,
        image,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to fetch exercise image",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: corsHeaders },
    );
  }
});
