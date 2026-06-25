// Generates a goal-based 7-day meal plan (lose weight / build muscle / etc.)
// tailored to the user's calorie target, macros, diet preferences, allergies,
// and how often they cook. Returns structured JSON the app renders day-by-day.

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

const SYSTEM_PROMPT =
  `You are a wellness meal-planning assistant. You produce general, balanced
nutrition guidance ONLY — you are NOT a dietitian. Never prescribe extreme or
very-low-calorie diets, never diagnose, never recommend supplements. If the
inputs look unsafe (e.g. an extremely low calorie target), gently raise it to a
sensible level. Tailor the plan to the user's goal:
- "Lose weight": a modest, sustainable calorie deficit, high protein, high
  fibre, filling whole foods.
- "Build muscle": a slight calorie surplus, high protein spread across meals,
  enough carbs to fuel training.
- "Maintain weight": balanced macros around maintenance.
- Otherwise: balanced, energy-supporting meals.
Respect diet preferences and allergies strictly. Keep meal "items" short and
practical for the user's cooking frequency. Output ONLY valid JSON.`;

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
    const goal = (body.goal as string) || "Improve fitness";
    const calorieTarget = (body.calorie_target as number) || 2000;
    const macros = body.macros ?? {};
    const mealsPerDay = (body.meals_per_day as string) || "3";
    const dietPrefs: string[] = body.diet_prefs ?? [];
    const allergies = (body.allergies as string) || "";
    const cooking = (body.cooking_frequency as string) || "Cook some meals";

    const userMsg = `Create a 7-day meal plan.
Goal: ${goal}
Daily calorie target: ${calorieTarget} kcal
Macro targets: protein ${macros.protein_g ?? "?"}g, carbs ${macros.carbs_g ?? "?"}g, fat ${macros.fat_g ?? "?"}g
Meals per day: ${mealsPerDay}
Diet preferences: ${dietPrefs.length ? dietPrefs.join(", ") : "none"}
Allergies / foods to avoid: ${allergies || "none"}
Cooking frequency: ${cooking}

Return ONLY valid JSON in exactly this shape (no markdown, no commentary):
{
  "goal_summary": "one short sentence describing the dietary strategy for this goal",
  "daily_calories": ${calorieTarget},
  "macros": { "protein_g": number, "carbs_g": number, "fat_g": number },
  "days": [
    {
      "day": "Monday",
      "meals": [
        { "meal": "Breakfast", "items": "short description", "calories": number, "protein_g": number, "carbs_g": number, "fat_g": number }
      ],
      "total_calories": number
    }
  ],
  "tips": ["2-4 short, practical tips for this goal"],
  "disclaimer": "This meal plan is general wellness guidance, not medical or dietary advice. Consult a registered dietitian for personalized nutrition."
}
Include all 7 days (Monday–Sunday), each with exactly ${mealsPerDay === "5+" ? "5" : mealsPerDay} meals. Keep "items" concise. Vary meals across the week.`;

    const completion = await client.chat.completions.create({
      model: MODEL,
      max_tokens: 4096,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: userMsg },
      ],
    });

    let jsonStr = (completion.choices[0]?.message?.content ?? "").trim();
    if (jsonStr.startsWith("```json")) jsonStr = jsonStr.slice(7);
    if (jsonStr.startsWith("```")) jsonStr = jsonStr.slice(3);
    if (jsonStr.endsWith("```")) jsonStr = jsonStr.slice(0, -3);
    jsonStr = jsonStr.trim();

    const plan = JSON.parse(jsonStr);
    if (!Array.isArray(plan.days) || plan.days.length === 0) {
      throw new Error("Invalid meal plan structure from AI");
    }

    return new Response(JSON.stringify(plan), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("meal-plan error:", error);
    return new Response(
      JSON.stringify({
        error: "Failed to generate meal plan",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: corsHeaders },
    );
  }
});
