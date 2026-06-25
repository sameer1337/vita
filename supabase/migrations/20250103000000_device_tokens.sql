-- Firebase Cloud Messaging device tokens, one row per device per user.
-- The admin "send push" function reads these with the service-role key to
-- deliver notifications via FCM.

create table if not exists public.device_tokens (
  token      text primary key,
  user_id    uuid references auth.users (id) on delete cascade,
  platform   text,                         -- 'android' | 'ios' | 'web'
  updated_at timestamptz not null default now()
);

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- Each user manages only their own device tokens.
drop policy if exists "own device_tokens" on public.device_tokens;
create policy "own device_tokens" on public.device_tokens
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
