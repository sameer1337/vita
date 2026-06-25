-- Phase D: per-user cloud backup/restore for Vita.
--
-- Run this in the Supabase SQL Editor (project ref mdcdugxgxfnpoymhiexv).
-- All access is gated by row-level security so a signed-in user can only ever
-- read or write their own rows.

-- 1. One row per user: plan, profile, smoking + reminder settings (all jsonb).
create table if not exists public.user_state (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  plan       jsonb,
  profile    jsonb,
  smoking    jsonb,
  reminders  jsonb,
  updated_at timestamptz not null default now()
);

-- 2. One row per (user, day): water, meals, workout completion, cigarettes…
create table if not exists public.daily_logs (
  user_id    uuid not null references auth.users (id) on delete cascade,
  date       text not null,                 -- yyyy-MM-dd
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);

-- 3. Row-level security.
alter table public.user_state enable row level security;
alter table public.daily_logs enable row level security;

drop policy if exists "own user_state" on public.user_state;
create policy "own user_state" on public.user_state
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "own daily_logs" on public.daily_logs;
create policy "own daily_logs" on public.daily_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Private storage bucket for meal photos (Phase D media sync).
insert into storage.buckets (id, name, public)
values ('meal-photos', 'meal-photos', false)
on conflict (id) do nothing;

-- Users may manage only files under a folder named after their uid,
-- e.g. meal-photos/<uid>/<file>.jpg
drop policy if exists "own meal photos" on storage.objects;
create policy "own meal photos" on storage.objects
  for all
  using (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
