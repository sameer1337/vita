import OpenAI from "npm:openai@^4";
import { allowedNames } from "../_shared/exercise_catalog.ts";

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

interface OnboardingAnswers {
  goal: string;
  sex: string;
  age: number;
  height_cm: number;
  weight_kg: number;
  target_weight_kg?: number;
  activity_level: string;
  equipment: string[];
  days_per_week: number;
  minutes_per_session: number;
  limitations: string[];
  diet_prefs: string[];
  allergies?: string;
  meals_per_day: string;
  cooking_frequency: string;
  stress_level: number;
  sleep_quality: number;
  mood: number;
}

interface PlanResponse {
  calorie_target: number;
  macros: {
    protein_g: number;
    carbs_g: number;
    fat_g: number;
  };
  workout_plan: Array<{
    day: string;
    focus: string;
    exercises: Array<{
      name: string;
      sets: number;
      reps: string;
      rest_seconds: number;
    }>;
  }>;
  sample_meals: Array<{
    meal: string;
    items: string;
    calories: number;
  }>;
  mind_checkin_prompt: string;
  weekly_focus_tip: string;
  refer_to_professional: boolean;
  disclaimer: string;
}

const SYSTEM_PROMPT = `You are a wellness planning assistant. You generate general fitness, nutrition, and stress-management guidance ONLY. You are NOT a doctor, dietitian, or therapist.

CRITICAL RULES:
- Never diagnose any condition.
- Never recommend medication or supplements.
- Never give clinical mental-health advice.
- If user data suggests eating disorder, severe injury, or crisis indicators, return refer_to_professional: true with a supportive message. Do NOT generate a restrictive plan.
- Always include the disclaimer field exactly as provided.
- Output ONLY valid JSON, no markdown, no preamble.`;

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
    const body: OnboardingAnswers = await req.json();

    // Validate required fields
    if (
      !body.goal ||
      !body.sex ||
      !body.age ||
      !body.height_cm ||
      !body.weight_kg
    ) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: corsHeaders,
      });
    }

    const userDataStr = JSON.stringify(body, null, 2);

    // Constrain the workout to exercises we have verified demo GIFs for, so the
    // demo always matches the movement and the user's available equipment.
    const allowed = allowedNames(body.equipment ?? []);
    const exerciseRule = allowed
      ? `\n\nIMPORTANT — exercise selection: choose every exercise's "name" ONLY from this approved list (use the name exactly as written). Do not invent other exercises, and do not use any equipment the user doesn't have:\n${allowed.join(", ")}.`
      : "";

    const completion = await client.chat.completions.create({
      model: MODEL,
      max_tokens: 2000,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: `Generate a personalized wellness plan for this user:

${userDataStr}${exerciseRule}

Return ONLY valid JSON matching this schema (no other text):
{
  "calorie_target": number,
  "macros": {
    "protein_g": number,
    "carbs_g": number,
    "fat_g": number
  },
  "workout_plan": [
    {
      "day": "Mon-Sun",
      "focus": "string",
      "exercises": [
        {
          "name": "string",
          "sets": number,
          "reps": "string (e.g., '8-12' or '30 seconds')",
          "rest_seconds": number
        }
      ]
    }
  ],
  "sample_meals": [
    {
      "meal": "Breakfast/Lunch/Dinner/Snack",
      "items": "string",
      "calories": number
    }
  ],
  "mind_checkin_prompt": "string",
  "weekly_focus_tip": "string",
  "refer_to_professional": boolean,
  "disclaimer": "This plan is general wellness guidance, not medical advice. Consult a physician or registered dietitian before making significant changes, especially with existing health conditions."
}`,
        },
      ],
    });

    // Extract the response text
    const responseText = completion.choices[0]?.message?.content ?? "";

    // Parse JSON, allowing for markdown code blocks
    let jsonStr = responseText.trim();
    if (jsonStr.startsWith("```json")) {
      jsonStr = jsonStr.slice(7);
    }
    if (jsonStr.startsWith("```")) {
      jsonStr = jsonStr.slice(3);
    }
    if (jsonStr.endsWith("```")) {
      jsonStr = jsonStr.slice(0, -3);
    }
    jsonStr = jsonStr.trim();

    const plan: PlanResponse = JSON.parse(jsonStr);

    // Validate response structure
    if (
      !plan.calorie_target ||
      !plan.macros ||
      !plan.workout_plan ||
      !plan.sample_meals
    ) {
      throw new Error("Invalid plan structure from AI");
    }

    return new Response(JSON.stringify(plan), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: "Failed to generate plan",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: corsHeaders }
    );
  }
});
