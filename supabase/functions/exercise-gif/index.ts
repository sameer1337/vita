// Resolves an (AI-generated) exercise name to a real ExerciseDB demo GIF.
//
// First call for a name: fuzzy-matches it against ExerciseDB, downloads the
// GIF once, caches it in the public `exercise-gifs` Storage bucket, and records
// the name→url mapping in `exercise_media`. Later calls (any user) return the
// cached public URL instantly — so the rate-limited RapidAPI key is hit at most
// once per unique exercise.

import { overrideMap } from "../_shared/exercise_catalog.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

// Vetted name → confirmed ExerciseDB id (or null = use the offline demo).
const OVERRIDE = overrideMap();

const HOST = "exercisedb.p.rapidapi.com";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BUCKET = "exercise-gifs";

const STOP = new Set(
  "the a an with on to of and or your for from down up ups out into at by"
    .split(" "),
);
const EQUIP_PREFIX =
  /^(dumbbell|barbell|cable|machine|smith|kettlebell|band|resistance band|bodyweight|weighted|assisted)\s+/;

function clean(s: string): string {
  return s
    .toLowerCase()
    .replace(/\([^)]*\)/g, " ")
    .replace(/[^a-z0-9\s-]/g, " ")
    .replace(/-/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}
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

const json = (payload: unknown, status = 200) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

// ---- Cache (exercise_media table) --------------------------------------

async function cacheGet(nameKey: string) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/exercise_media?name_key=eq.${encodeURIComponent(nameKey)}&select=*`,
    { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` } },
  );
  if (!res.ok) return null;
  const rows = await res.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

async function cachePut(row: Record<string, unknown>) {
  await fetch(`${SUPABASE_URL}/rest/v1/exercise_media`, {
    method: "POST",
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      Prefer: "resolution=merge-duplicates",
    },
    body: JSON.stringify(row),
  });
}

function publicUrl(id: string): string {
  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${id}.gif`;
}

// Make sure the GIF for `id` is in our public bucket (download once from the
// keyed RapidAPI endpoint if missing). Returns the public URL, or null if the
// image couldn't be fetched.
async function ensureGif(id: string, apiKey: string): Promise<string | null> {
  const url = publicUrl(id);
  const head = await fetch(url, { method: "HEAD" });
  if (head.ok) return url;
  const imgRes = await fetch(
    `https://${HOST}/image?exerciseId=${id}&resolution=360`,
    { headers: { "x-rapidapi-host": HOST, "x-rapidapi-key": apiKey } },
  );
  if (!imgRes.ok) return null;
  const bytes = new Uint8Array(await imgRes.arrayBuffer());
  return (await uploadGif(id, bytes)) ? url : null;
}

async function uploadGif(id: string, bytes: Uint8Array): Promise<boolean> {
  const res = await fetch(
    `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${id}.gif`,
    {
      method: "POST",
      headers: {
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
        "Content-Type": "image/gif",
        "x-upsert": "true",
      },
      body: bytes,
    },
  );
  return res.ok || res.status === 409; // 409 = already exists
}

// ---- ExerciseDB matching ------------------------------------------------

// deno-lint-ignore no-explicit-any
async function findExercise(rawName: string, apiKey: string): Promise<any> {
  const headers = { "x-rapidapi-host": HOST, "x-rapidapi-key": apiKey };
  const cleaned = depluralize(clean(rawName));
  const sig = significantWords(cleaned);
  const needed = sig.length === 0 ? 0 : Math.max(1, Math.ceil(sig.length / 2));
  const wantsBodyweight = !EQUIP_PREFIX.test(cleaned);
  const cleanedWords = cleaned.split(" ").filter(Boolean).length;

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

      let score = shared * 1000;
      if (en === cleaned) score += 100000;
      else if (en.endsWith(cleaned)) score += 30000;
      else if (en.includes(cleaned)) score += 10000;
      if (wantsBodyweight && eq === "body weight") score += 4000;
      // Strongly prefer the most basic variant: penalise names that pad the
      // query with extra words ("clap push up", "power point plank", "… with
      // stork stance"), and break ties toward shorter names.
      const enWords = en.split(" ").filter(Boolean).length;
      score -= Math.max(0, enWords - cleanedWords) * 3000;
      score -= en.length;

      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }
    if (best) break;
  }
  return best;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Accept the name from a POST body or a GET query param.
  let rawName: string | undefined;
  if (req.method === "POST") {
    const body = await req.json().catch(() => ({}));
    rawName = (body.name as string | undefined)?.trim();
  } else if (req.method === "GET") {
    rawName = new URL(req.url).searchParams.get("name")?.trim() ?? undefined;
  } else {
    return json({ error: "Method not allowed" }, 405);
  }

  if (!rawName) return json({ error: "Missing name" }, 400);

  const apiKey = Deno.env.get("EXERCISEDB_API_KEY");
  if (!apiKey) return json({ error: "EXERCISEDB_API_KEY not configured" }, 500);

  const nameKey = depluralize(clean(rawName));
  if (!nameKey) return json({ found: false });

  try {
    // 0. Vetted override: a hand-verified id (always the right movement and
    //    equipment), or an explicit null meaning "use the offline demo".
    const ov = OVERRIDE.get(nameKey);
    if (ov !== undefined) {
      if (ov.id === null) return json({ found: false });
      const url = await ensureGif(ov.id, apiKey);
      if (!url) return json({ found: false });
      await cachePut({
        name_key: nameKey,
        exercise_id: ov.id,
        resolved_name: ov.name,
        public_url: url,
        found: true,
      });
      return json({ found: true, url, name: ov.name });
    }

    // 1. Cache hit?
    const cached = await cacheGet(nameKey);
    if (cached) {
      return cached.found
        ? json({
            found: true,
            url: cached.public_url,
            name: cached.resolved_name,
            target: cached.target,
          })
        : json({ found: false });
    }

    // 2. Resolve via ExerciseDB.
    const best = await findExercise(rawName, apiKey);
    if (!best) {
      await cachePut({ name_key: nameKey, found: false });
      return json({ found: false });
    }

    // 3. Download + store the GIF once (reused if another name already mapped
    //    to this id).
    const url = await ensureGif(best.id, apiKey);
    if (!url) return json({ found: false });

    await cachePut({
      name_key: nameKey,
      exercise_id: best.id,
      resolved_name: best.name,
      target: best.target,
      public_url: url,
      found: true,
    });

    return json({ found: true, url, name: best.name, target: best.target });
  } catch (error) {
    console.error("exercise-gif error:", error);
    return json(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});
