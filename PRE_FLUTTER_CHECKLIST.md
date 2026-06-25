# Pre-Flutter Checklist

Before we start building the Flutter frontend, complete these steps:

---

## 1. Get API Keys ✓

### Supabase
- [ ] Go to [supabase.com](https://supabase.com)
- [ ] Create an account (free tier)
- [ ] Create a new project called "vita"
- [ ] Wait for database initialization (~2 min)
- [ ] Go to **Settings → API** and copy:
  - [ ] Project URL (e.g., `https://xxxx.supabase.co`)
  - [ ] Anon Key
  - [ ] Service Role Key (keep secret!)

### Anthropic
- [ ] Go to [console.anthropic.com](https://console.anthropic.com)
- [ ] Sign up / log in
- [ ] Create an API key
- [ ] Copy it (starts with `sk-ant-...`)
- [ ] Set a usage limit (recommended: $10/month for safety)

---

## 2. Set Up Supabase Project ✓

Follow **`docs/SUPABASE_SETUP.md`** exactly:

- [ ] Step 1: Create Supabase project ✓
- [ ] Step 2: Get connection details ✓
- [ ] Step 3: Deploy database schema
  - [ ] Go to **SQL Editor** in Supabase
  - [ ] Create new query
  - [ ] Copy entire `supabase/migrations/20250101000000_init_vita_schema.sql`
  - [ ] Paste into editor
  - [ ] Click **Run**
  - [ ] Verify no errors (all tables created)

- [ ] Step 4: Configure Authentication
  - [ ] Enable Email auth (should be default)
  - [ ] Enable Google OAuth (need Google Cloud credentials)
  - [ ] Enable Apple OAuth (need Apple Developer account later, optional for now)

- [ ] Step 5: Create `.env.local` file (copy from `.env.example`)
  ```
  SUPABASE_URL=https://your-project-id.supabase.co
  SUPABASE_ANON_KEY=eyJhbGc...
  ANTHROPIC_API_KEY=sk-ant-...
  ```
  - [ ] Fill in your actual values
  - [ ] Add `.env.local` to `.gitignore`

- [ ] Step 6: Deploy Edge Functions
  - [ ] Install Supabase CLI: `npm install -g supabase`
  - [ ] In `D:\vita`, run: `supabase link --project-id your-project-id`
  - [ ] Deploy each function:
    ```bash
    supabase functions deploy generate-plan
    supabase functions deploy lookup-food
    supabase functions deploy analyze-food-photo
    supabase functions deploy adapt-plan
    ```
  - [ ] Confirm each deployment succeeds

- [ ] Step 7: Set Edge Function Secrets
  - [ ] In Supabase dashboard, go to **Edge Functions**
  - [ ] Click **Manage Secrets**
  - [ ] Add:
    - `ANTHROPIC_API_KEY` = your API key
    - `SUPABASE_URL` = your project URL
    - `SUPABASE_SERVICE_ROLE_KEY` = from Settings → API

- [ ] Step 8: Schedule Weekly Adaptation Job
  - [ ] Go to **Edge Functions**
  - [ ] Click **adapt-plan**
  - [ ] Go to **Scheduled** tab
  - [ ] Click **Create Schedule**
  - [ ] Cron: `0 8 * * 1` (Monday 8 AM UTC)
  - [ ] Click **Create**

- [ ] Step 9: Test the Connection
  - [ ] Open PowerShell or terminal
  - [ ] Run the curl command from `docs/SUPABASE_SETUP.md` Step 10
  - [ ] Confirm you get back a JSON plan (not an error)

---

## 3. Install Flutter SDK ✓

- [ ] Go to [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
- [ ] Download Flutter SDK
- [ ] Extract to `C:\flutter` (avoid paths with spaces)
- [ ] Add `C:\flutter\bin` to system PATH:
  - [ ] Search "Environment Variables" in Start menu
  - [ ] Edit `Path` environment variable
  - [ ] Add `C:\flutter\bin`
  - [ ] Click OK

- [ ] Open a **NEW** PowerShell window
- [ ] Run: `flutter doctor`
- [ ] Resolve any issues:
  - [ ] If Android SDK missing: install Android Studio, run `flutter doctor --android-licenses`
  - [ ] If Xcode missing (Mac only): install from App Store

- [ ] Run: `flutter doctor -v` and confirm:
  - ✓ Flutter
  - ✓ Android toolchain
  - ✓ Chrome (for web)

---

## 4. Ready to Build ✓

Once all above are complete:

1. Come back here and say **"Flutter is ready"**
2. I'll run **Prompt 1** to create the Flutter project scaffold
3. We'll test on Android emulator + Chrome
4. Then move to **Prompt 2** (onboarding screens)

---

## Checklist Summary

### APIs & Keys
- [ ] Supabase account + project created
- [ ] Supabase connection details saved
- [ ] Anthropic API key created
- [ ] `.env.local` filled in

### Supabase Setup
- [ ] Database schema deployed
- [ ] Auth providers configured (email, Google)
- [ ] 4 Edge Functions deployed
- [ ] Secrets set in dashboard
- [ ] Weekly adaptation job scheduled
- [ ] API tested with curl (returns plan JSON)

### Flutter
- [ ] Flutter SDK installed to `C:\flutter`
- [ ] `C:\flutter\bin` added to PATH
- [ ] `flutter doctor` returns no errors

---

## Troubleshooting

**"Flutter command not found"**
- Did you restart PowerShell after adding to PATH? Open a NEW window.
- Is `C:\flutter\bin` actually in PATH? Verify in System Properties.

**"Could not find files for the given pattern" when deploying Edge Functions**
- Are you in the `D:\vita` directory?
- Did you run `supabase link --project-id your-id` first?

**"Edge Function secrets not working"**
- Are they spelled exactly right? (case-sensitive in code)
- Did you wait a few seconds after saving before testing?

**Supabase schema deployment failed**
- Copy the SQL again from `supabase/migrations/20250101000000_init_vita_schema.sql`
- Paste entire file (not partial)
- Check for syntax errors in the error message

---

**Once all items are checked, reply: "Ready to build Vita!" and we'll start Prompt 1.** 🚀
