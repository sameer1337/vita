// Vetted exercise catalog shared by `generate-plan` (constrains the AI's
// exercise choices) and `exercise-gif` (maps each name to a confirmed
// ExerciseDB demo GIF).
//
// Why this exists: the AI used to invent arbitrary exercise names, which the
// GIF resolver then fuzzy-matched against ExerciseDB — often landing on the
// wrong movement or an equipment variant (a "bodyweight" user seeing a
// dumbbell GIF). By limiting the AI to names we have hand-verified IDs for, the
// demo always matches the exercise and respects the user's equipment.
//
// `id` is the confirmed ExerciseDB id. `id: null` means there is no good demo
// GIF in the (free-tier) catalog for this movement, so the client should fall
// back to its offline animated figure — which is still accurate for these
// (e.g. a squat or plank) and far better than a wrong GIF.

export interface CatalogEntry {
  /** Canonical display name the AI must use verbatim. */
  name: string;
  /** Confirmed ExerciseDB id, or null to use the offline animated demo. */
  id: string | null;
  /** Equipment tier this exercise needs. */
  equip: "bw" | "db";
}

export const CATALOG: CatalogEntry[] = [
  // ---- Bodyweight ----
  { name: "Push-up", id: "0662", equip: "bw" },
  { name: "Pull-up", id: "0652", equip: "bw" },
  { name: "Burpee", id: "1160", equip: "bw" },
  { name: "Mountain climbers", id: "0630", equip: "bw" },
  { name: "Jumping jacks", id: "3223", equip: "bw" },
  { name: "High knees", id: null, equip: "bw" },
  { name: "Butt kicks", id: null, equip: "bw" },
  { name: "Squat", id: null, equip: "bw" },
  { name: "Jump squat", id: "0514", equip: "bw" },
  { name: "Wall sit", id: null, equip: "bw" },
  { name: "Walking lunge", id: "1460", equip: "bw" },
  { name: "Reverse lunge", id: null, equip: "bw" },
  { name: "Glute bridge", id: "3013", equip: "bw" },
  { name: "Bench dip", id: "0129", equip: "bw" },
  { name: "Chest dip", id: "0251", equip: "bw" },
  { name: "Plank", id: null, equip: "bw" },
  { name: "Side plank", id: null, equip: "bw" },
  { name: "Crunch", id: "0267", equip: "bw" },
  { name: "Bicycle crunch", id: "0003", equip: "bw" },
  { name: "Sit-up", id: "0735", equip: "bw" },
  { name: "Russian twist", id: "0687", equip: "bw" },
  { name: "Dead bug", id: "0276", equip: "bw" },
  { name: "Flutter kicks", id: "0459", equip: "bw" },
  { name: "Lying leg raise", id: "0620", equip: "bw" },
  { name: "Bird dog", id: null, equip: "bw" },
  { name: "Inchworm", id: "1471", equip: "bw" },
  { name: "Bear crawl", id: "3360", equip: "bw" },
  { name: "Shoulder taps", id: "3699", equip: "bw" },
  { name: "Skater hops", id: "3361", equip: "bw" },
  { name: "Superman", id: null, equip: "bw" },
  { name: "Jump rope", id: "2612", equip: "bw" },
  { name: "World's greatest stretch", id: "1604", equip: "bw" },

  // ---- Dumbbell ----
  { name: "Dumbbell goblet squat", id: "1760", equip: "db" },
  { name: "Dumbbell squat", id: "0413", equip: "db" },
  { name: "Dumbbell lunge", id: "0336", equip: "db" },
  { name: "Dumbbell Romanian deadlift", id: "1459", equip: "db" },
  { name: "Dumbbell deadlift", id: "0300", equip: "db" },
  { name: "Dumbbell bent over row", id: "0293", equip: "db" },
  { name: "Dumbbell biceps curl", id: "0294", equip: "db" },
  { name: "Dumbbell lateral raise", id: "0334", equip: "db" },
  { name: "Dumbbell front raise", id: "0310", equip: "db" },
  { name: "Dumbbell fly", id: "0308", equip: "db" },
  { name: "Dumbbell step-up", id: "0431", equip: "db" },
  { name: "Dumbbell standing calf raise", id: "0417", equip: "db" },
];

/** Normalize a name to a stable lookup key (lowercase, depluralized, no
 *  punctuation). MUST match the `nameKey` computed in exercise-gif. */
export function catalogKey(s: string): string {
  return s
    .toLowerCase()
    .replace(/\([^)]*\)/g, " ")
    .replace(/[^a-z0-9\s-]/g, " ")
    .replace(/-/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .split(" ")
    .map((w) => (w.length > 2 && w.endsWith("s") ? w.slice(0, -1) : w))
    .join(" ")
    .trim();
}

/** name_key → { id, name } for the GIF resolver's override table. */
export function overrideMap(): Map<string, { id: string | null; name: string }> {
  const m = new Map<string, { id: string | null; name: string }>();
  for (const e of CATALOG) m.set(catalogKey(e.name), { id: e.id, name: e.name });
  return m;
}

/** Exercise names the AI may use for the given onboarding equipment list.
 *  Bodyweight is always allowed; dumbbell moves are added when the user has
 *  any weights. Returns null for "Full gym access" — those users get free
 *  choice (the resolver still fuzzy-matches and prefers correct equipment). */
export function allowedNames(equipment: string[]): string[] | null {
  const eq = equipment.map((e) => e.toLowerCase());
  if (eq.some((e) => e.includes("full gym"))) return null;
  const hasWeights = eq.some(
    (e) => e.includes("dumbbell") || e.includes("home gym"),
  );
  return CATALOG.filter((e) => e.equip === "bw" || (hasWeights && e.equip === "db"))
    .map((e) => e.name);
}
