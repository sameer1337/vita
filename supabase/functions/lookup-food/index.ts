import OpenAI from "npm:openai@^4";

const client = new OpenAI({
  apiKey: Deno.env.get("GROQ_API_KEY"),
  baseURL: "https://api.groq.com/openai/v1",
});

const MODEL = "llama-3.3-70b-versatile";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface NutritionItem {
  name: string;
  quantity: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
}

interface LookupResponse {
  items: NutritionItem[];
  totals: {
    calories: number;
    protein_g: number;
    carbs_g: number;
    fat_g: number;
  };
}

const round1 = (n: number) => Math.round((Number(n) || 0) * 10) / 10;
const intOf = (n: number) => Math.round(Number(n) || 0);

/// Ask the model to estimate nutrition for a free-text meal description. The
/// model handles any cuisine/portion (including foods not in any fixed table),
/// which is the whole point of an AI nutrition app.
async function estimateNutrition(
  description: string,
): Promise<NutritionItem[]> {
  const completion = await client.chat.completions.create({
    model: MODEL,
    temperature: 0.2,
    max_tokens: 800,
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "You are a precise nutritionist. Estimate realistic nutrition for " +
          "the meal the user describes, for the portion implied. If a portion " +
          "is given in grams or a count, estimate for exactly that amount; if " +
          "it is vague, assume one typical single serving. Cover any cuisine, " +
          "including regional and home-cooked dishes. Respond with ONLY a JSON " +
          'object of the form: {"items":[{"name":string,"quantity":string,' +
          '"calories":number,"protein_g":number,"carbs_g":number,' +
          '"fat_g":number}]}. Use grams for macros and kcal for calories. ' +
          "Never return an empty items array for real food.",
      },
      { role: "user", content: description },
    ],
  });

  const text = completion.choices[0]?.message?.content ?? "{}";
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch (_) {
    return [];
  }

  const rawItems = (parsed as { items?: unknown }).items;
  if (!Array.isArray(rawItems)) return [];

  return rawItems
    .map((raw): NutritionItem | null => {
      const m = raw as Record<string, unknown>;
      const name = typeof m.name === "string" ? m.name : "";
      if (!name) return null;
      return {
        name,
        quantity: typeof m.quantity === "string" ? m.quantity : "1 serving",
        calories: intOf(m.calories as number),
        protein_g: round1(m.protein_g as number),
        carbs_g: round1(m.carbs_g as number),
        fat_g: round1(m.fat_g as number),
      };
    })
    .filter((x): x is NutritionItem => x !== null);
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

  try {
    const body = await req.json();
    const foodDescription = body.food_description as string;

    if (!foodDescription || !foodDescription.trim()) {
      return new Response(
        JSON.stringify({ error: "Missing food_description" }),
        { status: 400, headers: corsHeaders },
      );
    }

    const items = await estimateNutrition(foodDescription);

    if (items.length === 0) {
      return new Response(
        JSON.stringify({
          error:
            "Could not estimate nutrition for that. Try describing the meal " +
            "with a bit more detail.",
        }),
        { status: 400, headers: corsHeaders },
      );
    }

    // Always compute totals on the server so they stay consistent.
    const totals = {
      calories: items.reduce((s, i) => s + i.calories, 0),
      protein_g: round1(items.reduce((s, i) => s + i.protein_g, 0)),
      carbs_g: round1(items.reduce((s, i) => s + i.carbs_g, 0)),
      fat_g: round1(items.reduce((s, i) => s + i.fat_g, 0)),
    };

    const response: LookupResponse = { items, totals };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: "Failed to process food description",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: corsHeaders },
    );
  }
});
