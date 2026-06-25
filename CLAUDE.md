# Vita: AI Wellness Coach

Full App Store name: "Vita: AI Wellness Coach"
Platform: Flutter (iOS, Android, Web from one codebase)

## Tech Stack
- Frontend: Flutter (Riverpod for state management)
- Backend: Supabase (Postgres, Auth, Storage, Edge Functions)
- AI: Anthropic Claude API — model claude-sonnet-4-6 — called from Edge Functions ONLY, never from client
- Food Database: USDA FoodData Central + Open Food Facts (free APIs, no key needed)
- Charts: fl_chart
- Camera: image_picker

## Project Structure
- /lib/screens — one screen per .dart file
- /lib/widgets — reusable UI components
- /lib/services — API calls, Supabase, external services
- /lib/models — data classes / models
- /lib/providers — Riverpod providers
- /supabase/migrations — SQL migration files
- /supabase/functions — Edge Functions (TypeScript)

## Critical Rules
1. NO medical claims anywhere. Every AI-generated guidance screen MUST display:
   "General wellness guidance only — not medical advice."
2. Claude API is NEVER called from the Flutter client. Always via Supabase Edge Function.
3. MVP scope: no ads, no wearable sync, no barcode scanning, no social features.
4. Camera food scanning IS in scope (image_picker + Claude vision via Edge Function).
5. If refer_to_professional flag is true, show supportive banner + crisis resources. Never push a harder plan.
6. Onboarding: no backend writes until user taps "Save My Plan" on screen 16.
7. Code style: modular, one widget per file, clean separation of concerns.
8. Test each prompt's output on Android emulator AND Chrome before moving to the next step.

## Onboarding Flow (17 screens, local state only until screen 16)
Screens 0–16 collect answers into a single OnboardingAnswers Riverpod state object.
No Supabase writes until signup is complete after screen 16.

## Safety: refer_to_professional
- Triggered by AI when mood/stress logs suggest crisis
- Shows calm banner: supportive message + crisis resource links
- Does NOT block access to other features
- Crisis resources: 988 (US), Crisis Text Line (HOME to 741741), iasp.info

## App Theme
- Soft, calming palette (no bright neon)
- Clean minimal design, generous spacing
- Primary color: a calm blue-green or sage green (decide during build)
