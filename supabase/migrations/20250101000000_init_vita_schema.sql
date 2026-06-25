-- Vita: AI Wellness Coach — Initial Schema

-- ============================================================================
-- 1. USERS (extends auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- ============================================================================
-- 2. ONBOARDING_ANSWERS (one row per user)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.onboarding_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  goal TEXT NOT NULL,
  sex TEXT NOT NULL,
  age INTEGER NOT NULL,
  height_cm INTEGER NOT NULL,
  weight_kg FLOAT NOT NULL,
  target_weight_kg FLOAT,
  activity_level TEXT NOT NULL,
  equipment JSONB NOT NULL DEFAULT '[]'::jsonb,
  days_per_week INTEGER NOT NULL,
  minutes_per_session INTEGER NOT NULL,
  limitations JSONB NOT NULL DEFAULT '[]'::jsonb,
  diet_prefs JSONB NOT NULL DEFAULT '[]'::jsonb,
  allergies TEXT,
  meals_per_day TEXT NOT NULL,
  cooking_frequency TEXT NOT NULL,
  stress_level INTEGER NOT NULL CHECK (stress_level >= 1 AND stress_level <= 10),
  sleep_quality INTEGER NOT NULL CHECK (sleep_quality >= 1 AND sleep_quality <= 10),
  mood INTEGER NOT NULL CHECK (mood >= 1 AND mood <= 10),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_onboarding_answers_user_id ON public.onboarding_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_answers_created_at ON public.onboarding_answers(created_at);

-- ============================================================================
-- 3. PLANS (one current plan per user, updated weekly)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  calorie_target INTEGER NOT NULL,
  macros JSONB NOT NULL,
  workout_plan JSONB NOT NULL,
  sample_meals JSONB NOT NULL,
  mind_checkin_prompt TEXT NOT NULL,
  weekly_focus_tip TEXT NOT NULL,
  refer_to_professional BOOLEAN DEFAULT FALSE,
  disclaimer TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_plans_user_id ON public.plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_updated_at ON public.plans(updated_at);

-- ============================================================================
-- 4. WORKOUT_LOGS (one entry per logged workout)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workout_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  exercise_name TEXT NOT NULL,
  sets_completed INTEGER NOT NULL,
  feedback TEXT NOT NULL CHECK (feedback IN ('done', 'too_easy', 'too_hard')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON public.workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_created_at ON public.workout_logs(created_at);

-- ============================================================================
-- 5. MEAL_LOGS (one entry per logged meal)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.meal_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  food_items JSONB NOT NULL,
  total_calories INTEGER NOT NULL,
  total_protein_g INTEGER NOT NULL,
  total_carbs_g INTEGER NOT NULL,
  total_fat_g INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_meal_logs_user_id ON public.meal_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_logs_created_at ON public.meal_logs(created_at);

-- ============================================================================
-- 6. MOOD_LOGS (one entry per daily check-in)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.mood_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  stress_level INTEGER NOT NULL CHECK (stress_level >= 1 AND stress_level <= 10),
  sleep_quality INTEGER NOT NULL CHECK (sleep_quality >= 1 AND sleep_quality <= 10),
  mood INTEGER NOT NULL CHECK (mood >= 1 AND mood <= 10),
  journal_entry TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_mood_logs_user_id ON public.mood_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_logs_created_at ON public.mood_logs(created_at);

-- ============================================================================
-- 7. FOOD_CACHE (cached nutrition lookups to reduce API calls)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.food_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  food_name TEXT NOT NULL,
  quantity_description TEXT NOT NULL,
  calories INTEGER NOT NULL,
  protein_g INTEGER NOT NULL,
  carbs_g INTEGER NOT NULL,
  fat_g INTEGER NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('usda', 'openfoodfacts')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(food_name, quantity_description, source)
);

CREATE INDEX IF NOT EXISTS idx_food_cache_name ON public.food_cache(food_name);
CREATE INDEX IF NOT EXISTS idx_food_cache_created_at ON public.food_cache(created_at);

-- ============================================================================
-- 8. ADAPTATIONS (audit trail of weekly plan updates)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.adaptations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  previous_plan_id UUID,
  new_plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_adaptations_user_id ON public.adaptations(user_id);
CREATE INDEX IF NOT EXISTS idx_adaptations_created_at ON public.adaptations(created_at);

-- ============================================================================
-- Enable Row Level Security (RLS)
-- ============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adaptations ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS Policies (users can only see/edit their own data)
-- ============================================================================

-- Users table: only authenticated users can see their own row
CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- Onboarding answers: users see only their own
CREATE POLICY "Users can view their onboarding answers" ON public.onboarding_answers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own onboarding answers" ON public.onboarding_answers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their onboarding answers" ON public.onboarding_answers
  FOR UPDATE USING (auth.uid() = user_id);

-- Plans: users see only their own
CREATE POLICY "Users can view their plan" ON public.plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plan" ON public.plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their plan" ON public.plans
  FOR UPDATE USING (auth.uid() = user_id);

-- Workout logs: users see only their own
CREATE POLICY "Users can view their workout logs" ON public.workout_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout logs" ON public.workout_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their workout logs" ON public.workout_logs
  FOR DELETE USING (auth.uid() = user_id);

-- Meal logs: users see only their own
CREATE POLICY "Users can view their meal logs" ON public.meal_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own meal logs" ON public.meal_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their meal logs" ON public.meal_logs
  FOR DELETE USING (auth.uid() = user_id);

-- Mood logs: users see only their own
CREATE POLICY "Users can view their mood logs" ON public.mood_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood logs" ON public.mood_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their mood logs" ON public.mood_logs
  FOR DELETE USING (auth.uid() = user_id);

-- Food cache: everyone can read (it's public), only service can insert
CREATE POLICY "Everyone can read food cache" ON public.food_cache
  FOR SELECT USING (true);

-- Adaptations: users can view their own
CREATE POLICY "Users can view their adaptations" ON public.adaptations
  FOR SELECT USING (auth.uid() = user_id);
