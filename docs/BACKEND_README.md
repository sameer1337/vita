# Vita Backend Architecture

## Overview

Vita's backend is **serverless and database-driven**, built on Supabase + Edge Functions + Anthropic Claude API.

- **Database:** PostgreSQL (managed by Supabase)
- **Authentication:** Supabase Auth (email, Apple, Google)
- **API:** Supabase Edge Functions (serverless TypeScript)
- **AI Engine:** Anthropic Claude API (claude-sonnet-4-6)
- **Storage:** Supabase Storage (for optional food photos)

---

## Architecture Flow

```
Flutter App
    ↓
Supabase Client (supabase_flutter)
    ↓
Supabase Edge Functions (TypeScript/Deno)
    ↓
┌─────────────────────────────────────┐
│ PostgreSQL Database (Supabase)      │
│ - users                              │
│ - onboarding_answers                │
│ - plans                              │
│ - workout_logs, meal_logs, mood_logs│
│ - food_cache, adaptations           │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ External APIs (called by Functions) │
│ - Anthropic Claude API              │
│ - USDA FoodData Central             │
│ - Open Food Facts                   │
└─────────────────────────────────────┘
```

---

## Database Schema (8 Tables)

| Table | Purpose | Rows per User |
|-------|---------|---|
| **users** | Auth user profile | 1 |
| **onboarding_answers** | Initial questionnaire | 1 |
| **plans** | Current wellness plan | 1 (updated weekly) |
| **workout_logs** | Logged exercise sessions | Many |
| **meal_logs** | Logged meals | Many |
| **mood_logs** | Daily check-ins | Many |
| **food_cache** | Cached nutrition data | Shared (global) |
| **adaptations** | Audit trail of plan updates | Many |

### Key Design Decisions

1. **One plan per user** — updated in-place weekly (not historical)
2. **RLS (Row-Level Security)** — users can only see their own data
3. **JSONB for flexible data** — `plan` and `workout_plan` can evolve without migrations
4. **food_cache** — shared globally to reduce USDA/OpenFoodFacts API calls
5. **adaptations** — audit trail for debugging plan changes

---

## Edge Functions (4 serverless APIs)

### 1. **generate-plan** (POST)
- **When:** User completes onboarding
- **Input:** OnboardingAnswers JSON
- **Process:** Call Claude API with system prompt + user data
- **Output:** Plan JSON (calories, macros, workout plan, sample meals, mood prompt)
- **Side effect:** Stored in `plans` table by Flutter app

### 2. **lookup-food** (POST)
- **When:** User logs a meal via text
- **Input:** `"2 eggs, 1 toast, 1 banana"`
- **Process:** Parse with Claude → lookup each item in USDA FoodData Central → cache result
- **Output:** Structured nutrition data (items + totals)
- **Caching:** Checks `food_cache` first, only hits APIs if needed

### 3. **analyze-food-photo** (POST)
- **When:** User taps camera button, captures a photo
- **Input:** Base64-encoded JPEG or image URL
- **Process:** Send to Claude vision API → identify foods + estimate weights
- **Output:** Identified foods with estimated portions (g)
- **Next step:** App calls lookup-food for each identified item

### 4. **adapt-plan** (scheduled, no manual invocation)
- **When:** Every Monday at 8 AM UTC
- **Process:** Fetch user's 7-day logs → call Claude with adaptation rules
- **Output:** Updated plan (or same if no changes needed)
- **Triggers:** `refer_to_professional` flag if mood/stress critical

---

## Authentication Flow

```
1. User signs up via Flutter
   ↓
2. Supabase Auth creates auth.users row
   ↓
3. Flutter auto-creates public.users row (trigger or app-side)
   ↓
4. All subsequent queries filtered by RLS: WHERE user_id = auth.uid()
```

Supabase handles JWT refresh automatically. Flutter app checks `Supabase.instance.client.auth.currentUser` before API calls.

---

## Row-Level Security (RLS)

All tables have RLS policies:

```sql
-- Example: Users can only view/edit their own workout logs
CREATE POLICY "Users can view their workout logs" 
  ON workout_logs FOR SELECT 
  USING (auth.uid() = user_id);
```

This means:
- ✓ User can query their own data
- ✗ User cannot see other users' data
- ✗ Unauthenticated users see nothing

---

## API Security

1. **Anon Key** (used by Flutter app)
   - Has limited permissions (SELECT, INSERT, UPDATE on user's own rows)
   - Safe to embed in Flutter code
   
2. **Service Role Key** (used by Edge Functions)
   - Full database access
   - Kept secret in Supabase dashboard
   - Edge Functions run with this key

3. **JWT Verification**
   - Edge Functions verify the request JWT automatically
   - `auth.uid()` inside Edge Functions is the authenticated user

---

## Data Flow: Onboarding Example

```
1. User answers 16 onboarding questions (all local state)
   
2. Taps "Save My Plan"
   ↓
3. Flutter calls: supabase.functions.invoke('generate-plan', body: answers)
   ↓
4. Edge Function generate-plan:
   - Receives answers JSON
   - Calls Claude API with system prompt + user data
   - Validates JSON response
   - Returns plan JSON
   ↓
5. Flutter receives plan, shows plan preview
   ↓
6. User taps "Create Account"
   - Flutter calls Supabase Auth sign up
   - Creates auth.users + public.users row
   ↓
7. Flutter saves to database:
   - INSERT into onboarding_answers
   - INSERT into plans
   ↓
8. User navigates to Home dashboard
   ✓ Plan is now persistent
```

---

## Weekly Adaptation Flow

```
Every Monday 8 AM UTC:
   ↓
Supabase scheduler invokes adapt-plan function
   ↓
For each user in the database:
   - Fetch last 7 days of workout_logs (feedback: done/too_easy/too_hard)
   - Fetch last 7 days of meal_logs (totals)
   - Fetch last 7 days of mood_logs (mood/stress/sleep)
   ↓
Call Claude API with adaptation prompt:
   "If too easy 2+ times, increase intensity."
   "If mood < 5/10 for 5+ days, set refer_to_professional: true"
   ↓
Validate response JSON
   ↓
UPDATE plans SET ... WHERE user_id = ?
   ↓
INSERT INTO adaptations (audit trail)
   ↓
On next app open, user sees updated plan
✓ If refer_to_professional = true, show safety banner + crisis resources
```

---

## Food Nutrition Lookups

**Priority order:**

1. **food_cache table** (fastest)
   - Check if this exact food + quantity is already cached
   - If yes, return instantly

2. **USDA FoodData Central API** (free, comprehensive)
   - Query for the food name
   - Extract calories + macros
   - Insert into food_cache

3. **Open Food Facts API** (free, branded foods)
   - Fallback if USDA doesn't find it
   - Good for packaged items

4. **Estimation fallback** (last resort)
   - If no API finds it, use a generic estimate with a disclaimer

**Why cache?** Reduce API calls. Most users log similar foods (eggs, chicken, rice, etc.). One lookup per unique food per app.

---

## Error Handling Strategy

### Edge Functions

```typescript
try {
  // Call Claude API
  const response = await anthropic.messages.create(...)
  // Parse response
  const plan = JSON.parse(responseText)
  // Validate
  if (!plan.calorie_target) throw new Error("Invalid plan")
  return new Response(JSON.stringify(plan), { status: 200 })
} catch (error) {
  console.error(error)
  return new Response(
    JSON.stringify({ error: "Failed to generate plan", details: error.message }),
    { status: 500 }
  )
}
```

### Flutter App

```dart
try {
  final response = await Supabase.instance.client.functions.invoke(
    'generate-plan',
    body: onboardingData,
  );
  final plan = jsonDecode(response) as Map<String, dynamic>;
} on FunctionException catch (e) {
  showSnackBar('API Error: ${e.message}');
} catch (e) {
  showSnackBar('Unexpected error: $e');
}
```

---

## Monitoring & Debugging

### Check Edge Function Logs

Supabase Dashboard → Edge Functions → [function-name] → Logs

```
[12:34:56] Received request: {"goal": "Lose weight", ...}
[12:34:58] Claude API response: 200 OK
[12:35:01] Plan generated: calorie_target=2200
```

### Check Database Queries

Supabase Dashboard → Database → Query Inspector

```
SELECT * FROM workout_logs 
  WHERE user_id = 'abc-123-def' 
  AND created_at > NOW() - INTERVAL '7 days'
```

### Monitor Costs

1. **API calls:** Anthropic charges per token
   - ~100 tokens per plan generation
   - ~50 tokens per food lookup
   - ~200 tokens per weekly adaptation
   
2. **Database:** Supabase free tier includes 500k rows/month

3. **Storage:** Minimal (unless storing full-res food photos)

---

## Next Steps (After Flutter is Ready)

1. **Initialize Flutter project** with Supabase dependencies
2. **Follow Prompt 1** to set up folder structure
3. **Follow Prompt 4** to build onboarding screens
4. **Follow Prompt 5** to wire up auth + plan saving
5. **Integrate with backend** via API contracts (see `docs/API_CONTRACTS.md`)

All backend is **production-ready** right now. Just needs the Flutter frontend!
