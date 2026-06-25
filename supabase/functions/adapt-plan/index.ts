import OpenAI from "npm:openai@^4";

const client = new OpenAI({
  apiKey: Deno.env.get("GROQ_API_KEY"),
  baseURL: "https://api.groq.com/openai/v1",
});

const MODEL = "llama-3.3-70b-versatile";

// This is a Supabase scheduled function.
// Schedule it as a cron job in Supabase dashboard: 0 8 * * 1 (every Monday at 8 AM UTC)

interface PlanResponse {
  calorie_target?: number;
  macros?: {
    protein_g?: number;
    carbs_g?: number;
    fat_g?: number;
  };
  workout_plan?: Array<{
    day: string;
    focus: string;
    exercises: Array<{
      name: string;
      sets: number;
      reps: string;
      rest_seconds: number;
    }>;
  }>;
  sample_meals?: Array<{
    meal: string;
    items: string;
    calories: number;
  }>;
  mind_checkin_prompt?: string;
  weekly_focus_tip?: string;
  refer_to_professional?: boolean;
  disclaimer?: string;
}

async function getSupabaseClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseKey) {
    throw new Error("Missing Supabase credentials");
  }

  return { supabaseUrl, supabaseKey };
}

async function fetchUserData(userId: string, supabaseUrl: string, supabaseKey: string) {
  // Fetch onboarding answers
  const answersRes = await fetch(
    `${supabaseUrl}/rest/v1/onboarding_answers?user_id=eq.${userId}`,
    {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  );

  if (!answersRes.ok) {
    throw new Error("Failed to fetch onboarding answers");
  }

  const answers = await answersRes.json();
  return answers.length > 0 ? answers[0] : null;
}

async function fetchUserPlan(userId: string, supabaseUrl: string, supabaseKey: string) {
  const planRes = await fetch(
    `${supabaseUrl}/rest/v1/plans?user_id=eq.${userId}`,
    {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  );

  if (!planRes.ok) {
    throw new Error("Failed to fetch plan");
  }

  const plans = await planRes.json();
  return plans.length > 0 ? plans[0] : null;
}

async function fetchLastWeekLogs(
  userId: string,
  supabaseUrl: string,
  supabaseKey: string
) {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const dateStr = sevenDaysAgo.toISOString();

  // Workout logs
  const workoutRes = await fetch(
    `${supabaseUrl}/rest/v1/workout_logs?user_id=eq.${userId}&created_at=gte.${dateStr}`,
    {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  );
  const workoutLogs = (await workoutRes.json()) || [];

  // Meal logs
  const mealRes = await fetch(
    `${supabaseUrl}/rest/v1/meal_logs?user_id=eq.${userId}&created_at=gte.${dateStr}`,
    {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  );
  const mealLogs = (await mealRes.json()) || [];

  // Mood logs
  const moodRes = await fetch(
    `${supabaseUrl}/rest/v1/mood_logs?user_id=eq.${userId}&created_at=gte.${dateStr}`,
    {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  );
  const moodLogs = (await moodRes.json()) || [];

  // Summarize
  const tooEasyCount = workoutLogs.filter(
    (w: any) => w.feedback === "too_easy"
  ).length;
  const tooHardCount = workoutLogs.filter(
    (w: any) => w.feedback === "too_hard"
  ).length;
  const avgMood =
    moodLogs.length > 0
      ? Math.round(
          moodLogs.reduce((sum: number, m: any) => sum + m.mood, 0) /
            moodLogs.length
        )
      : 5;
  const avgStress =
    moodLogs.length > 0
      ? Math.round(
          moodLogs.reduce((sum: number, m: any) => sum + m.stress_level, 0) /
            moodLogs.length
        )
      : 5;
  const avgSleep =
    moodLogs.length > 0
      ? Math.round(
          moodLogs.reduce((sum: number, m: any) => sum + m.sleep_quality, 0) /
            moodLogs.length
        )
      : 5;

  return {
    workoutCount: workoutLogs.length,
    tooEasyCount,
    tooHardCount,
    avgMood,
    avgStress,
    avgSleep,
    totalMealLogDays: new Set(mealLogs.map((m: any) => m.created_at)).size,
  };
}

async function updatePlan(
  userId: string,
  newPlan: PlanResponse,
  supabaseUrl: string,
  supabaseKey: string
) {
  const updateRes = await fetch(
    `${supabaseUrl}/rest/v1/plans?user_id=eq.${userId}`,
    {
      method: "PATCH",
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ...newPlan,
        updated_at: new Date().toISOString(),
      }),
    }
  );

  if (!updateRes.ok) {
    throw new Error("Failed to update plan");
  }
}

async function processAllUsers() {
  const { supabaseUrl, supabaseKey } = await getSupabaseClient();

  // Fetch all users
  const usersRes = await fetch(`${supabaseUrl}/rest/v1/users`, {
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
    },
  });

  if (!usersRes.ok) {
    console.error("Failed to fetch users");
    return;
  }

  const users = await usersRes.json();

  for (const user of users) {
    try {
      console.log(`Processing adaptation for user ${user.id}`);

      // Fetch user data
      const answers = await fetchUserData(user.id, supabaseUrl, supabaseKey);
      const plan = await fetchUserPlan(user.id, supabaseUrl, supabaseKey);
      const logs = await fetchLastWeekLogs(user.id, supabaseUrl, supabaseKey);

      if (!answers || !plan) {
        console.log(`Skipping user ${user.id}: missing data`);
        continue;
      }

      // Build adaptation prompt
      const adaptationPrompt = `Given this user's current plan and their last week's logged data, adapt next week's plan.

USER DATA:
${JSON.stringify(answers, null, 2)}

CURRENT PLAN:
${JSON.stringify(plan, null, 2)}

LAST 7 DAYS SUMMARY:
- Workouts completed: ${logs.workoutCount}
- "Too easy" feedback: ${logs.tooEasyCount}
- "Too hard" feedback: ${logs.tooHardCount}
- Average mood: ${logs.avgMood}/10
- Average stress: ${logs.avgStress}/10
- Average sleep: ${logs.avgSleep}/10
- Days with meal logs: ${logs.totalMealLogDays}

ADAPTATION RULES:
- If "too easy" 2+ times, increase volume/intensity ~10%.
- If "too hard" or skipped 2+ sessions, reduce intensity and add recovery day.
- If mood/stress trend negative for 5+ days or if low mood for 3+ days, set refer_to_professional: true instead of pushing harder.
- If sleep quality poor (<5/10 for 3+ days), suggest shorter workouts and emphasize recovery.
- Return the same JSON schema, with only the updated fields (fill in the rest from current plan).`;

      const completion = await client.chat.completions.create({
        model: MODEL,
        max_tokens: 2000,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: adaptationPrompt,
          },
        ],
      });

      const responseText = completion.choices[0]?.message?.content ?? "{}";

      let jsonStr = responseText.trim();
      if (jsonStr.startsWith("```json")) jsonStr = jsonStr.slice(7);
      if (jsonStr.startsWith("```")) jsonStr = jsonStr.slice(3);
      if (jsonStr.endsWith("```")) jsonStr = jsonStr.slice(0, -3);

      const adaptedPlan: PlanResponse = JSON.parse(jsonStr.trim());

      // Merge with current plan (use adapted fields, fallback to current)
      const mergedPlan = {
        calorie_target:
          adaptedPlan.calorie_target || plan.calorie_target,
        macros: { ...plan.macros, ...adaptedPlan.macros },
        workout_plan:
          adaptedPlan.workout_plan || plan.workout_plan,
        sample_meals:
          adaptedPlan.sample_meals || plan.sample_meals,
        mind_checkin_prompt:
          adaptedPlan.mind_checkin_prompt || plan.mind_checkin_prompt,
        weekly_focus_tip:
          adaptedPlan.weekly_focus_tip || plan.weekly_focus_tip,
        refer_to_professional:
          adaptedPlan.refer_to_professional !== undefined
            ? adaptedPlan.refer_to_professional
            : plan.refer_to_professional,
        disclaimer:
          adaptedPlan.disclaimer || plan.disclaimer,
      };

      // Update the plan in DB
      await updatePlan(user.id, mergedPlan, supabaseUrl, supabaseKey);
      console.log(`Successfully adapted plan for user ${user.id}`);
    } catch (error) {
      console.error(
        `Error adapting plan for user ${user.id}:`,
        error instanceof Error ? error.message : String(error)
      );
      // Continue to next user
    }
  }
}

Deno.serve(async (req: Request) => {
  // This function is invoked by Supabase's scheduler
  // It doesn't take any parameters from the request
  try {
    await processAllUsers();
    return new Response(
      JSON.stringify({ message: "Adaptation job completed" }),
      { status: 200 }
    );
  } catch (error) {
    console.error("Adaptation job failed:", error);
    return new Response(
      JSON.stringify({
        error: "Adaptation job failed",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500 }
    );
  }
});
