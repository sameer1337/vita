# Vita — Design Blueprint & Figma Master Prompt

A complete, paste-ready brief for designing every Vita screen in Figma (or any
AI design tool). All tokens and screens below match the live Flutter app.

---

## 1. Screen & navigation hierarchy

```
Vita (mobile app)
│
├── Onboarding (LIGHT theme, full-screen, 20 steps)
│   ├── Top progress bar + Back / mute(voice) controls
│   ├── Per-step "character" hero (emoji in a colored circle) + animated blobs
│   ├── Step 0  Name
│   ├── Step 1  Email
│   ├── Step 2  Date of birth (→ age)
│   ├── Step 3  Primary goal            (single-select)
│   ├── Step 4  Sex                     (single-select)
│   ├── Step 5  Height                  (cm ⇄ ft/in toggle)
│   ├── Step 6  Weight                  (kg ⇄ lb toggle)
│   ├── Step 7  Target weight           (conditional on goal)
│   ├── Step 8  Activity level          (single-select)
│   ├── Step 9  Equipment               (multi-select chips)
│   ├── Step 10 Days per week           (stepper / chips)
│   ├── Step 11 Minutes per session     (slider)
│   ├── Step 12 Limitations / injuries  (multi-select)
│   ├── Step 13 Diet preferences        (multi-select)
│   ├── Step 14 Allergies               (free text)
│   ├── Step 15 Meals per day           (single-select)
│   ├── Step 16 Cooking frequency       (single-select)
│   ├── Step 17 Preferred workout time  (time picker)
│   ├── Step 18 Stress level            (slider 1–10)
│   ├── Step 19 Sleep quality           (slider 1–10)
│   └── Step 20 Mood today              (slider 1–10) → "Save my plan"
│
├── Plan-generating loading screen (sage spinner + reassuring copy)
│
└── HomeShell (DARK + sage, bottom navigation + "Log meal" FAB)
    │
    ├── [Tab 1] Dashboard / Home
    │   ├── Header: greeting, name, 🔥 streak chip, avatar
    │   ├── (optional) Refer-to-professional / crisis banner
    │   ├── Mood check-in card  ⇄  Mood-acknowledged reply card
    │   ├── Today rings card: Calories · Water · Steps  + "250 ml water" + reset
    │   ├── Weather & hydration card (emoji, feels-like °, advice)
    │   ├── Today's workout hero (gradient) → Workout Player
    │   ├── "Your week" horizontal day strip (✓ on completed) → Workout Player
    │   ├── Daily targets: macro donut (kcal-left center) + P/C/F rows
    │   ├── "This week's focus" card
    │   ├── "Mind check-in" card
    │   └── Disclaimer (not medical advice)
    │
    ├── [Tab 2] Coach (AI chat)
    │   ├── Header: 🌱 avatar, "Vita Coach", subtitle
    │   ├── Message list: assistant bubbles (left, dark) + user bubbles (right, sage)
    │   ├── Typing indicator (• • •)
    │   └── Composer: multiline text field + send FAB
    │
    ├── [Tab 3] Plan
    │   ├── "Your plan" title
    │   ├── Daily targets card (kcal / protein / carbs / fat)
    │   ├── Workout week card: expandable day tiles → exercise list + "Start workout"
    │   └── Sample meals card
    │
    ├── [FAB / pushed] Log a meal
    │   ├── Segmented toggle: Photo ⇄ Describe
    │   ├── Photo: 4:3 preview + Camera / Gallery buttons
    │   ├── Describe: multiline meal text field
    │   ├── "Analyze meal" button (→ loading)
    │   ├── Result card: label, kcal, P/C/F pills, Redo / Add to today
    │   └── Error state box
    │
    └── [pushed] Workout Player (LIGHT, focused mode)
        ├── App bar: day focus + mute toggle
        ├── Segment progress bar
        ├── Phase chip: WORK (sage) / REST (blue)
        ├── "Exercise X of N"
        ├── Animated exercise demo (category rings + icon)
        ├── Exercise name + set/reps
        ├── Circular countdown timer
        ├── Controls: prev · pause/play · skip
        └── Completion screen (✓, "Workout complete!", Done)
```

---

## 2. THE MASTER PROMPT  (copy everything in this block)

> You are designing **Vita**, a mobile **AI wellness & fitness coach** app
> (iOS + Android, 390×844 baseline). Produce a complete, polished, production-
> quality UI kit and all screens listed below, as a cohesive design system.
> Follow this brief exactly.

### Product
Vita turns a friendly 20-step onboarding into a personalized plan: daily
calorie/macro targets, a weekly workout program with a guided player, food
logging by photo or text, water + step + mood tracking, weather-aware hydration
advice, and an AI coach chat. Tone: **calm, warm, encouraging, trustworthy** —
a supportive coach, never a shouty fitness app. Audience: everyday adults
starting or maintaining a wellness routine.

### Design language
- **Two contexts, one family.** Onboarding is **light & airy** (welcoming first
  impression). The main app (Home/Coach/Plan/Workout) is **dark + sage**
  (focused, premium, easy on the eyes).
- Soft, rounded, generous. Large rounded corners, soft shadows, lots of
  breathing room. **No neon, no harsh gradients.** Nature-inspired sage palette.
- Friendly micro-personality: emoji "characters", gentle motion, encouraging
  microcopy.

### Design tokens

**Color — brand**
| Token | Hex | Use |
|---|---|---|
| sage | `#6B9080` | primary brand / buttons / strength |
| deepSage | `#2E3D38` | dark text on light |
| sageLight | `#9CC3B2` | accents on dark |
| softBackground | `#F6F8F7` | onboarding bg |

**Color — dark surfaces (main app)**
| Token | Hex |
|---|---|
| darkBg | `#14201B` |
| darkSurface | `#1E2C26` |
| darkSurfaceAlt | `#263A32` |
| text primary | `#FFFFFF` |
| text secondary | `white 70%` |
| text muted | `white 38–54%` |

**Color — accents (week strip, categories, charts)**
`#5B8DB8` blue · `#E39A53` orange · `#D16BA5` pink · `#7E6CC4` purple ·
`#6BA368` green · `#E0566E` red.

**Color — semantic**
- Macros: Protein `#6B9080`, Carbs `#5B8DB8`, Fat `#D9A86C`.
- Exercise categories: Strength `#6B9080`, Lower-body `#5B8DB8`, Core `#E39A53`,
  Cardio `#E0566E`, Mobility `#7E6CC4`.
- Calories ring `#6B9080`, Water ring `#5B8DB8`, Steps ring `#E39A53`.

**Typography** — clean humanist sans (Inter / SF Pro / Plus Jakarta Sans).
Display 24–26 / w800 · Title 16–18 / w700–800 · Body 14–15 / w400–500 ·
Caption 11–12 / muted. Headings tight, body line-height ~1.35.

**Spacing** 4 / 8 / 12 / 16 / 20 / 24. Screen padding 20. Card padding 16–22.

**Radius** chips/pills 20–24 (full) · cards 18–24 · inputs 14–16 · sheets 24 top.

**Elevation** flat by default; hero cards get one soft colored shadow
(e.g. sage @30% blur 24 y+12). Dark cards use subtle 1px white-6% borders, not shadows.

**Iconography** rounded Material icons. **Mood scale** uses emoji 😞 😕 😐 🙂 😄.

### Core components (build as a library first)
1. **Buttons** — Filled (sage, white text, radius 14), White-on-color (hero CTA),
   Tonal (translucent accent), Outlined, Icon button, **FAB.extended** ("Log meal").
2. **Stat ring** — circular progress (stroke 7, rounded cap) with center value +
   small unit, icon+label beneath. Three variants: Calories/Water/Steps.
3. **Cards** — dark surface, radius 20–24: plain, gradient hero, info card
   (tinted bg + emoji + title + body), weather card (left temp column + advice).
4. **Chips** — streak chip (🔥 + "N days"), phase chip (WORK/REST), select chip
   (single & multi states), day card (week strip: icon circle, day, focus, ✓).
5. **Segmented control** — 2-option (Photo / Describe).
6. **Macro pill** — small tile: grams value + P/C/F letter, tinted by macro color.
7. **Donut chart** — 3-segment macro ring with centered "kcal left".
8. **Chat bubbles** — assistant (left, darkSurface, tail bottom-left), user
   (right, sage, tail bottom-right); typing indicator bubble.
9. **Composer** — pill text field + circular send button.
10. **Inputs** — text field, slider (1–10 with value), measurement field with
    **unit toggle** (cm/ft, kg/lb), time picker trigger, DOB picker.
11. **Bottom navigation** — 3 items (Home / Coach / Plan), dark surface, sage
    indicator pill, with a center-docked Log-meal FAB on Home.
12. **Banners** — "general wellness, not medical advice" + crisis-resource banner.
13. **Animated exercise demo** — square tile: concentric pulsing rings + a
    bobbing category icon + a category label pill, tinted per category.

### States to include for each interactive screen
Empty · Loading (skeleton/spinner) · Filled/Default · Error · Success/Done ·
Disabled. Show **light & dark** where relevant (onboarding=light, app=dark).

### Screens to deliver (see hierarchy above for structure)
1. **Onboarding** — design a reusable step template (progress bar, character
   hero, animated soft background blobs, question, input area, Back + Continue),
   then 4–6 representative variants: single-select, multi-select chips, slider,
   measurement+unit-toggle, time picker, and the final "Save my plan" step.
2. **Plan-generating loading** — calm full screen, sage spinner, rotating
   reassurance copy.
3. **Dashboard** — full dark scroll: header+streak, mood check-in (and its
   acknowledged state), Today rings card with water controls, weather/hydration
   card, today's workout gradient hero, week strip with ✓, macro donut +
   targets, focus & mind cards, disclaimer.
4. **Coach chat** — header, conversation with both bubble types, typing state,
   composer; include an empty/first-message state.
5. **Plan** — targets card, expandable workout-week list, sample meals.
6. **Log a meal** — both Photo and Describe modes, the analyzing state, the
   editable result card, and an error state.
7. **Workout Player** — WORK and REST variants (different accent), the animated
   demo, timer ring, controls; plus the **completion** screen.
8. **Bottom-nav shell** — show all three tabs with the FAB.

### Accessibility & trust
WCAG-AA contrast on dark surfaces · tap targets ≥ 44px · never rely on color
alone (pair with icon/label) · always-visible "not medical advice" footer on
plan/dashboard · calm, non-judgmental copy.

### Output
Deliver as a structured Figma file: **Page 1 Foundations** (color, type,
spacing, elevation), **Page 2 Components** (the library above with variants &
states), **Page 3 Onboarding**, **Page 4 Main App** (Dashboard, Coach, Plan,
Log meal, Workout Player), each screen on a 390×844 frame, named clearly, using
Auto Layout and shared styles/variables for every token.

---

## 3. Suggested Figma file structure
```
📄 00 Cover / README
📄 01 Foundations      (colors as variables, type styles, spacing, radius, elevation)
📄 02 Components        (buttons, rings, cards, chips, nav, chat, inputs — all variants)
📄 03 Onboarding        (step template + variants, light theme)
📄 04 Main App          (Dashboard, Coach, Plan, Log meal, Workout player — dark)
📄 05 Flows / Prototype (onboarding → plan → home → workout; home → log meal; home → coach)
```
```
