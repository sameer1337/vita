import OpenAI from "npm:openai@^4";

const client = new OpenAI({
  apiKey: Deno.env.get("GROQ_API_KEY"),
  baseURL: "https://api.groq.com/openai/v1",
});

const MODEL = "meta-llama/llama-4-scout-17b-16e-instruct";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface IdentifiedFood {
  name: string;
  estimated_weight_g: number;
  description: string;
}

interface AnalysisResponse {
  identified_foods: IdentifiedFood[];
  confidence: string;
  note: string;
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

    // Accept either base64-encoded image or image URL
    const imageBase64 = body.image_base64 as string;
    const imageUrl = body.image_url as string;

    if (!imageBase64 && !imageUrl) {
      return new Response(
        JSON.stringify({
          error:
            "Missing image_base64 or image_url. Provide one image source.",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Build the vision message (OpenAI-compatible image_url format)
    const imageContent = imageBase64
      ? {
          type: "image_url" as const,
          image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
        }
      : {
          type: "image_url" as const,
          image_url: { url: imageUrl },
        };

    const completion = await client.chat.completions.create({
      model: MODEL,
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: [
            imageContent,
            {
              type: "text",
              text: `Identify all food items visible in this photo. For each item, estimate:
(1) the type of food
(2) approximate portion size/weight based on typical serving sizes and visual context

Return ONLY a JSON object with no other text:
{
  "identified_foods": [
    {
      "name": "grilled chicken",
      "estimated_weight_g": 150,
      "description": "medium-size breast"
    }
  ],
  "confidence": "high/medium/low",
  "note": "any caveats or assumptions"
}`,
            },
          ],
        },
      ],
    });

    const responseText = completion.choices[0]?.message?.content ?? "{}";

    let jsonStr = responseText.trim();
    if (jsonStr.startsWith("```json")) jsonStr = jsonStr.slice(7);
    if (jsonStr.startsWith("```")) jsonStr = jsonStr.slice(3);
    if (jsonStr.endsWith("```")) jsonStr = jsonStr.slice(0, -3);

    const analysis: AnalysisResponse = JSON.parse(jsonStr.trim());

    if (!analysis.identified_foods) {
      return new Response(
        JSON.stringify({
          error:
            "Could not identify food items in this image. Try a clearer photo.",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    return new Response(JSON.stringify(analysis), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: "Failed to analyze photo",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: corsHeaders }
    );
  }
});
