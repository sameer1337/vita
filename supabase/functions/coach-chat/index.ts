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

interface ChatMessage {
  role: "user" | "assistant";
  content: string;
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
    const messages = (body.messages as ChatMessage[] | undefined) ?? [];
    const context = (body.context as string | undefined) ?? "";

    if (messages.length === 0) {
      return new Response(JSON.stringify({ error: "No messages provided" }), {
        status: 400,
        headers: corsHeaders,
      });
    }

    const system = `You are Vita, a warm, encouraging AI wellness coach.
You help with workouts, nutrition, hydration, sleep, stress and motivation.
Keep replies short (2-4 sentences), friendly and practical. Use the user's
plan context when relevant. Never give medical diagnoses or treatment; for
anything that sounds like a medical or mental-health emergency, gently urge
them to contact a professional or local emergency services. Always frame
guidance as general wellness, not medical advice.

User's current plan context:
${context || "(no plan context provided)"}`;

    // Keep the last ~12 turns to stay well within free-tier limits.
    const trimmed = messages.slice(-12);

    const completion = await client.chat.completions.create({
      model: MODEL,
      max_tokens: 400,
      temperature: 0.7,
      messages: [
        { role: "system", content: system },
        ...trimmed.map((m) => ({ role: m.role, content: m.content })),
      ],
    });

    const reply =
      completion.choices[0]?.message?.content?.trim() ??
      "I'm here for you — could you say that another way?";

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("coach-chat error:", error);
    return new Response(
      JSON.stringify({
        error: "Failed to reach the coach",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: corsHeaders },
    );
  }
});
