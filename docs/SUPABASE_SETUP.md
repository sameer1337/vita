# Supabase Setup Guide for Vita

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up / log in
2. Click **"New Project"**
3. Enter project name: `vita` (or similar)
4. Choose a region closest to your users
5. Set a strong database password
6. Click **"Create New Project"** and wait for it to initialize (~2 min)

---

## Step 2: Get Your Connection Details

After your project is created:

1. Go to **Settings** → **API**
2. Copy and save:
   - **Project URL** (e.g., `https://xxxxxxxxxxxx.supabase.co`)
   - **Anon Key** (public, safe to use in Flutter)
   - **Service Role Key** (secret! keep secure, use only for Edge Functions)

---

## Step 3: Create the Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the entire contents of `/supabase/migrations/20250101000000_init_vita_schema.sql`
4. Paste into the query editor
5. Click **"Run"**
6. Wait for success (should show no errors)

✓ You now have all 8 tables with proper indexes and RLS policies.

---

## Step 4: Configure Authentication

1. Go to **Authentication** → **Providers**
2. Enable:
   - **Email** (default, already enabled)
   - **Apple** (for iOS)
   - **Google** (for web/Android)

3. For **Email**, go to **Authentication** → **Email Templates** and customize if desired.

4. For **Apple & Google**, you'll need OAuth credentials:
   - **Google:** Go to [console.cloud.google.com](https://console.cloud.google.com), create an OAuth 2.0 client (credentials), paste Client ID & Secret into Supabase
   - **Apple:** Requires Apple Developer account ($99/year); follow Supabase docs for setup

---

## Step 5: Create Environment File

Create `.env.local` in your Flutter project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
ANTHROPIC_API_KEY=sk-ant-...
```

**Keep `.env.local` in `.gitignore` — never commit secrets!**

---

## Step 6: Deploy Edge Functions

First, install Supabase CLI if you haven't:

```bash
npm install -g supabase
```

Then, in the `vita` project root:

```bash
supabase link --project-id your-project-id
supabase functions deploy generate-plan
supabase functions deploy lookup-food
supabase functions deploy analyze-food-photo
supabase functions deploy adapt-plan
```

Each should print a success message with the function URL.

---

## Step 7: Set Edge Function Secrets

1. In Supabase dashboard, go to **Edge Functions**
2. Click **"Manage Secrets"**
3. Add these secrets:

| Key | Value |
|-----|-------|
| `ANTHROPIC_API_KEY` | `sk-ant-...` (from Anthropic API key) |
| `SUPABASE_URL` | Your project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | From Settings → API |

---

## Step 8: Schedule the Weekly Adaptation Job

1. In Supabase dashboard, go to **Edge Functions**
2. Find **adapt-plan** function
3. Click on it, then go to the **"Scheduled"** tab
4. Click **"Create Schedule"**
5. Set:
   - **Cron Expression:** `0 8 * * 1` (Monday at 8 AM UTC)
   - Click **"Create"**

Now the plan adaptation runs automatically every Monday morning.

---

## Step 9: Set CORS & URL Configuration

1. Go to **Settings** → **API**
2. In **"CORS allowed origins"**, add your Flutter app URLs:
   - For local dev: `http://localhost:3000`, `http://localhost:8000`
   - For production: Your actual app domain

3. For **Redirect URLs** (auth), add:
   - Web: `http://localhost:3000/auth`
   - Mobile: `vita://auth` (or your custom scheme)

---

## Step 10: Test the Connection

In a terminal, test the API:

```bash
curl -X POST https://your-project.supabase.co/functions/v1/generate-plan \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "goal": "Lose weight",
    "sex": "Male",
    "age": 30,
    "height_cm": 180,
    "weight_kg": 85,
    "target_weight_kg": 75,
    "activity_level": "Moderately active",
    "equipment": ["Gym access"],
    "days_per_week": 5,
    "minutes_per_session": 45,
    "limitations": [],
    "diet_prefs": ["No restrictions"],
    "allergies": null,
    "meals_per_day": "3",
    "cooking_frequency": "Cook most meals",
    "stress_level": 5,
    "sleep_quality": 7,
    "mood": 6
  }'
```

If you get back a JSON plan, success! ✓

---

## Troubleshooting

### "Service Unavailable" when calling functions
- Check Edge Functions are deployed: `supabase functions list`
- Check secrets are set: **Edge Functions → Manage Secrets**
- Check logs: **Edge Functions → function-name → "Logs"** tab

### RLS errors when Flutter tries to query
- Make sure user is logged in (`Supabase.instance.client.auth.currentUser != null`)
- Check RLS policy allows the operation (they should be set up correctly in the migration)

### CORS errors
- Add your app origin to **Settings → API → CORS allowed origins**

---

## Local Development (Optional)

To test Supabase locally before deploying:

```bash
supabase start
supabase db push
supabase functions serve
```

This runs a local Supabase stack. Test your Edge Functions locally, then deploy to production.

See [Supabase local docs](https://supabase.com/docs/guides/cli/local-development) for details.
