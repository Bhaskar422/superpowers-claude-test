-- ============================================================================
-- English Speaking Coach — initial schema
-- Implements §5 of the design spec.
-- ============================================================================

-- enums --------------------------------------------------------------------
create type english_level as enum ('beginner','intermediate','advanced');
create type session_mode  as enum ('free_chat','roleplay');
create type session_status as enum ('active','analyzing','complete','failed');
create type speaker_kind  as enum ('user','ai');
create type feedback_dimension as enum (
  'grammar','pronunciation','word_choice','fluency','vocabulary','confidence'
);
create type feedback_severity as enum ('minor','major');

-- users --------------------------------------------------------------------
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  native_language text,
  english_level english_level,
  daily_goal_minutes int not null default 10,
  is_paid boolean not null default false,
  paid_started_at timestamptz,
  trial_sessions_used int not null default 0 check (trial_sessions_used between 0 and 3),
  created_at timestamptz not null default now()
);

-- scenarios ----------------------------------------------------------------
create table public.scenarios (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text not null,
  category text not null,
  difficulty int not null check (difficulty between 1 and 3),
  system_prompt text not null,
  opening_line text not null,
  success_criteria text,
  is_premium_only boolean not null default false,
  created_at timestamptz not null default now()
);

-- sessions -----------------------------------------------------------------
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  mode session_mode not null,
  scenario_id uuid references public.scenarios(id),
  vapi_call_id text,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_seconds int,
  audio_url text,
  status session_status not null default 'active',
  constraint roleplay_needs_scenario check (
    (mode = 'free_chat' and scenario_id is null)
    or (mode = 'roleplay' and scenario_id is not null)
  )
);
create index sessions_user_idx on public.sessions(user_id, started_at desc);

-- transcript_turns ---------------------------------------------------------
create table public.transcript_turns (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  speaker speaker_kind not null,
  text text not null,
  start_ms int not null,
  end_ms int not null,
  turn_index int not null,
  unique (session_id, turn_index)
);
create index turns_session_idx on public.transcript_turns(session_id, turn_index);

-- feedback_reports ---------------------------------------------------------
create table public.feedback_reports (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null unique references public.sessions(id) on delete cascade,
  overall_summary text not null,
  grammar_score int not null check (grammar_score between 0 and 100),
  pronunciation_score int not null check (pronunciation_score between 0 and 100),
  word_choice_score int not null check (word_choice_score between 0 and 100),
  fluency_score int not null check (fluency_score between 0 and 100),
  vocabulary_score int not null check (vocabulary_score between 0 and 100),
  confidence_score int not null check (confidence_score between 0 and 100),
  success_criteria_met boolean,
  generated_at timestamptz not null default now()
);

-- feedback_items -----------------------------------------------------------
create table public.feedback_items (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  transcript_turn_id uuid references public.transcript_turns(id) on delete cascade,
  dimension feedback_dimension not null,
  severity feedback_severity not null,
  start_ms int not null,
  end_ms int not null,
  original_text text not null,
  suggested_text text,
  explanation text not null
);
create index items_session_idx on public.feedback_items(session_id);

-- user_skill_aggregates ----------------------------------------------------
create table public.user_skill_aggregates (
  user_id uuid not null references public.users(id) on delete cascade,
  dimension feedback_dimension not null,
  rolling_score int not null check (rolling_score between 0 and 100),
  session_count int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, dimension)
);

-- daily_activity -----------------------------------------------------------
create table public.daily_activity (
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null,
  sessions_count int not null default 0,
  minutes_practiced int not null default 0,
  primary key (user_id, date)
);

-- user_streak --------------------------------------------------------------
create table public.user_streak (
  user_id uuid primary key references public.users(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_session_date date,
  level int not null default 1
);

-- custom_scenarios (post-launch, schema reserved) --------------------------
create table public.custom_scenarios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  system_prompt text not null,
  opening_line text not null,
  success_criteria text,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- Row-level security
-- ============================================================================

-- scenarios is world-readable, no writes from clients
alter table public.scenarios enable row level security;
create policy scenarios_select_all on public.scenarios
  for select using (true);

-- helper: tables where "user owns the row by user_id" pattern applies
-- Each table gets its own policy block to make audits trivial.

alter table public.users enable row level security;
create policy users_self_select on public.users
  for select using (id = auth.uid());
create policy users_self_insert on public.users
  for insert with check (id = auth.uid());
create policy users_self_update on public.users
  for update using (id = auth.uid()) with check (id = auth.uid());

-- sessions: clients read only. Inserts/updates happen via the
-- /sessions/start and /vapi/session-ended Edge Functions under
-- the service-role key (which bypasses RLS by default).
alter table public.sessions enable row level security;
create policy sessions_self_select on public.sessions
  for select using (user_id = auth.uid());

alter table public.transcript_turns enable row level security;
create policy turns_self_select on public.transcript_turns
  for select using (
    exists (select 1 from public.sessions s
            where s.id = transcript_turns.session_id and s.user_id = auth.uid())
  );

alter table public.feedback_reports enable row level security;
create policy reports_self_select on public.feedback_reports
  for select using (
    exists (select 1 from public.sessions s
            where s.id = feedback_reports.session_id and s.user_id = auth.uid())
  );

alter table public.feedback_items enable row level security;
create policy items_self_select on public.feedback_items
  for select using (
    exists (select 1 from public.sessions s
            where s.id = feedback_items.session_id and s.user_id = auth.uid())
  );

alter table public.user_skill_aggregates enable row level security;
create policy aggregates_self_select on public.user_skill_aggregates
  for select using (user_id = auth.uid());

alter table public.daily_activity enable row level security;
create policy daily_self_select on public.daily_activity
  for select using (user_id = auth.uid());

alter table public.user_streak enable row level security;
create policy streak_self_select on public.user_streak
  for select using (user_id = auth.uid());

alter table public.custom_scenarios enable row level security;
create policy custom_self_select on public.custom_scenarios
  for select using (user_id = auth.uid());
create policy custom_self_insert on public.custom_scenarios
  for insert with check (user_id = auth.uid());
create policy custom_self_update on public.custom_scenarios
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy custom_self_delete on public.custom_scenarios
  for delete using (user_id = auth.uid());
