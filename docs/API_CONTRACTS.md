# Vita API Contracts

All API endpoints are **Supabase Edge Functions**. They are called from the Flutter frontend via `supabase.functions.invoke()`.

**Base URL:** `https://[your-supabase-url]/functions/v1`

---

## 1. generate-plan

**Endpoint:** `POST /generate-plan`

**Purpose:** Generate an AI-personalized wellness plan from onboarding answers.

### Request

```json
{
  "goal": "Lose weight",
  "sex": "Male",
  "age": 30,
  "height_cm": 180,
  "weight_kg": 85,
  "target_weight_kg": 75,
  "activity_level": "Moderately active",
  "equipment": ["Home, some equipment", "Gym access"],
  "days_per_week": 5,
  "minutes_per_session": 45,
  "limitations": [],
  "diet_prefs": ["No restrictions"],
  "allergies": "Peanuts",
  "meals_per_day": "3",
  "cooking_frequency": "Cook most meals",
  "stress_level": 6,
  "sleep_quality": 7,
  "mood": 7
}
```

### Response (200 OK)

```json
{
  "calorie_target": 2200,
  "macros": {
    "protein_g": 165,
    "carbs_g": 220,
    "fat_g": 73
  },
  "workout_plan": [
    {
      "day": "Mon",
      "focus": "Chest & Cardio",
      "exercises": [
        {
          "name": "Bench Press",
          "sets": 4,
          "reps": "8-10",
          "rest_seconds": 90
        },
        {
          "name": "Incline Dumbbell Press",
          "sets": 3,
          "reps": "10-12",
          "rest_seconds": 60
        }
      ]
    }
  ],
  "sample_meals": [
    {
      "meal": "Breakfast",
      "items": "2 eggs, 2 slices toast, 1 tbsp butter, 1 banana",
      "calories": 380
    }
  ],
  "mind_checkin_prompt": "What's one thing that made you smile today?",
  "weekly_focus_tip": "Stay consistent with your morning routine to build momentum.",
  "refer_to_professional": false,
  "disclaimer": "This plan is general wellness guidance, not medical advice. Consult a physician or registered dietitian before making significant changes, especially with existing health conditions."
}
```

### Error Response (400 / 500)

```json
{
  "error": "Failed to generate plan",
  "details": "..."
}
```

---

## 2. lookup-food

**Endpoint:** `POST /lookup-food`

**Purpose:** Parse a food description and return nutrition data.

### Request

```json
{
  "food_description": "2 eggs, 1 slice toast with butter, 1 banana"
}
```

### Response (200 OK)

```json
{
  "items": [
    {
      "name": "egg",
      "quantity": "2",
      "calories": 140,
      "protein_g": 12,
      "carbs_g": 1,
      "fat_g": 10
    },
    {
      "name": "toast",
      "quantity": "1",
      "calories": 80,
      "protein_g": 3,
      "carbs_g": 14,
      "fat_g": 1
    },
    {
      "name": "butter",
      "quantity": "1 tbsp",
      "calories": 100,
      "protein_g": 0,
      "carbs_g": 0,
      "fat_g": 11
    },
    {
      "name": "banana",
      "quantity": "1",
      "calories": 105,
      "protein_g": 1.3,
      "carbs_g": 27,
      "fat_g": 0.3
    }
  ],
  "totals": {
    "calories": 425,
    "protein_g": 16.3,
    "carbs_g": 42,
    "fat_g": 22.3
  }
}
```

### Error Response (400 / 500)

```json
{
  "error": "Could not identify nutrition for any items. Try describing your meal differently.",
  "details": "..."
}
```

---

## 3. analyze-food-photo

**Endpoint:** `POST /analyze-food-photo`

**Purpose:** Use Claude's vision to identify food items in a photo.

### Request (Option A: Base64)

```json
{
  "image_base64": "/9j/4AAQSkZJRgABAQAA..."
}
```

### Request (Option B: URL)

```json
{
  "image_url": "https://example.com/meal.jpg"
}
```

### Response (200 OK)

```json
{
  "identified_foods": [
    {
      "name": "grilled chicken breast",
      "estimated_weight_g": 150,
      "description": "medium-size piece, lightly charred"
    },
    {
      "name": "white rice",
      "estimated_weight_g": 200,
      "description": "side portion"
    },
    {
      "name": "steamed broccoli",
      "estimated_weight_g": 100,
      "description": "small florets"
    }
  ],
  "confidence": "high",
  "note": "Estimates based on typical plate sizes and visual context."
}
```

### Error Response (400 / 500)

```json
{
  "error": "Could not identify food items in this image. Try a clearer photo.",
  "details": "..."
}
```

---

## 4. adapt-plan

**Endpoint:** This is a **scheduled function** (cron job), not manually invoked.

**Schedule:** Every Monday at 8 AM UTC

**Purpose:** Adapt the user's plan based on last 7 days of logs (feedback, mood, consistency).

**Logic:**
- If "too easy" feedback 2+ times: increase intensity ~10%
- If "too hard" feedback 2+ times: reduce intensity, add recovery day
- If mood/stress trend very negative (5+ days below 5/10): set `refer_to_professional: true`
- If sleep quality poor: suggest shorter workouts, emphasize recovery

**Output:** Updates the `plans` table for each user and logs adaptation in the `adaptations` table.

---

## Common Patterns

### Call a function from Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final response = await Supabase.instance.client.functions.invoke(
  'generate-plan',
  body: onboardingData,
);

final plan = jsonDecode(response) as Map<String, dynamic>;
```

### Environment Variables Required

In Supabase dashboard, set these secrets for Edge Functions:

```
ANTHROPIC_API_KEY = "sk-ant-..."
SUPABASE_URL = "https://your-project.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGc..."
```

---

## Rate Limiting & Best Practices

1. **plan-generation:** Called once per user during onboarding. Cache the result.
2. **lookup-food:** Called every meal log. Cache common foods in `food_cache` table to reduce API hits.
3. **analyze-food-photo:** Called when user taps camera. Add a loading spinner (expect 5-15 sec).
4. **adapt-plan:** Runs automatically weekly. No user invocation needed.

---

## Error Handling in Flutter

Always wrap Edge Function calls in try-catch and show user-friendly messages:

```dart
try {
  final response = await Supabase.instance.client.functions.invoke('generate-plan', body: data);
  // Use response
} on FunctionException catch (e) {
  showSnackBar('Failed to generate plan: ${e.message}');
} catch (e) {
  showSnackBar('An error occurred: $e');
}
```
