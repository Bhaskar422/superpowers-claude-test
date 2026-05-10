# English Speaking Coach — Design Spec

**Date:** 2026-05-10
**Status:** Draft, pending implementation plan

## 1. Product summary

A mobile app that helps people improve their spoken English by holding voice conversations with an AI partner and giving comprehensive post-session feedback on six skill dimensions.

The user opens the app, picks **free chat** or a **roleplay scenario** from a curated library, and talks to the AI in a real-time voice call. The AI does **not** correct mistakes during the conversation — the call stays natural. When the session ends (the user taps end, the AI completes a roleplay's success criteria, or the 1-hour cap hits), the app shows an "Analyzing…" state for ~10–90 seconds and then opens an **interactive transcript** with inline highlights, tap-to-replay audio, and per-skill scores.

Audience: a mix of English learners and already-fluent speakers who want to refine delivery. The app meets both by letting the user self-rate their level at signup and by surfacing all six feedback dimensions on every session.

## 2. Goals and non-goals

**Goals**
- Make spoken-English practice feel like a real conversation, not a drill.
- Give comprehensive, specific, replayable feedback after every session.
- Build long-term engagement through visible skill progress, streaks, and goals.
- Ship a v1 that is fully usable on day one with a clean monetization path.

**Non-goals (v1)**
- Writing/text-chat practice. Voice-only.
- Multi-user / social features (peer practice, leaderboards beyond the user's own profile).
- Offline mode. The app requires connectivity.
- Custom user-authored scenarios. Schema is reserved; UI and entitlement checks ship behind a flag and unlock for paid users with ≥30 sessions in a future release.
- Push notifications, web companion, voice cloning.

## 3. Target experience

### 3.1 Onboarding
Sign up (email or Apple/Google via Supabase Auth) → quick profile (native language, self-rated English level: beginner / intermediate / advanced, daily goal in minutes — default 10) → home screen. No placement test in v1; user skill aggregates accumulate from real sessions.

### 3.2 Starting a session
From home, tap **Start session**. Choose mode:
- **Free chat** — straight into the call with a friendly opener.
- **Roleplay** — browse the curated library (filters by category and difficulty), pick a scenario, see the brief, tap **Start**.

Trial users (no active subscription) see remaining trial sessions in the picker.

### 3.3 In-session
Single-screen voice UI: a pulsing voice orb that indicates active speaker, an end-call button, and a soft session timer. **No real-time transcript** during the call — the user focuses on speaking. The AI greets with the scenario's `opening_line` (or a free-chat opener) and the conversation begins.

Hard caps:
- 5 minutes per session for trial users.
- 1 hour per session for paid users.
- The user can end at any time.

### 3.4 Session end → analysis
On end, the app shows an **Analyzing…** state. Behind the scenes, the backend ingests the recording and transcript from the voice-agent platform and runs the analysis pipeline. Latency target: under 30 seconds for a 5-minute session, under 90 seconds for a full hour. The screen shows per-step progress so the wait isn't opaque.

### 3.5 Feedback review (the heart of the product)
The interactive transcript opens. Top of screen:
- Overall summary (1–2 sentences).
- Six per-skill scores as small bars: grammar, pronunciation, word choice, fluency, vocabulary, confidence.

Body of screen: the full conversation as scrollable turns. User turns have inline highlights, color-coded by dimension. Tap any highlight → bottom sheet showing:
- The original audio clip (replayable).
- The original text and the suggested correction.
- A one-line explanation.

Tap a skill score at the top → transcript filters to just that dimension's items.

### 3.6 Progress / home
Home shows: current streak, level (derived from total sessions and skill milestones), today's progress vs daily goal, last session card, and a **Skills** tab that charts the six rolling scores over time. Recent sessions list is below; tap any past session to re-open its feedback report.

### 3.7 Premium unlock (post-launch entry-point, schema-reserved in v1)
When a user has `is_paid = true` AND `sessions_count ≥ 30`, the **Create your own scenario** entry-point becomes visible in the roleplay browser. The feature itself is out of v1 build scope, but the gating logic and database schema ship in v1.

## 4. Architecture

Four-box system:

1. **Flutter app** (iOS + Android). Holds Supabase auth tokens, short-lived session state, Vapi SDK for the live voice room. **No AI provider keys ever live on-device.**
2. **Supabase backend** — Postgres (with RLS), Auth, Storage, Realtime, and Edge Functions. Owns the curated scenario library, user profiles, sessions, transcripts, feedback reports, skill aggregates, streaks, and entitlement logic.
3. **Voice-agent platform** — Vapi (primary choice; LiveKit Agents acceptable alternative). Owns the live conversation: WebRTC audio, STT → LLM → TTS streaming, turn-taking, barge-in, latency tuning. Webhooks the backend on session end.
4. **Analysis pipeline** — Supabase Edge Function (or a small worker if Edge timeout limits are tight) triggered by Vapi's session-ended webhook. Calls Claude/GPT for transcript-based feedback, SpeechAce for pronunciation scoring, and runs cheap audio + transcript heuristics for fluency and confidence. Writes `feedback_report` and `feedback_items` to Postgres and notifies the app via Realtime.

External providers (called only from the backend / Vapi, never the device):
- **Claude (or GPT-4 class)** — conversation LLM and post-session analysis.
- **Whisper or Deepgram** — speech-to-text (via Vapi for live; possibly direct for analysis re-runs).
- **ElevenLabs** — text-to-speech for the AI partner's voice.
- **SpeechAce** — pronunciation scoring per word with phoneme-level detail.
- **RevenueCat** — cross-platform subscription management.

## 5. Domain model

All tables are in Postgres with RLS. Users can read/write only their own rows; `scenarios` is world-readable.

**`users`** — extension of `auth.users`
- `id` (FK to auth.users), `email`, `display_name`, `native_language`, `english_level` (`'beginner' | 'intermediate' | 'advanced'`), `daily_goal_minutes` (default 10), `is_paid` (bool), `paid_started_at`, `trial_sessions_used` (int, capped at 3), `created_at`

**`scenarios`** — curated roleplay library
- `id`, `slug`, `title`, `description`, `category` (`'work' | 'travel' | 'social' | 'daily' | ...`), `difficulty` (1–3), `system_prompt`, `opening_line`, `success_criteria` (text used by the analysis LLM to judge "did the user accomplish it?"), `is_premium_only` (bool, false at launch), `created_at`

**`sessions`** — one row per conversation
- `id`, `user_id`, `mode` (`'free_chat' | 'roleplay'`), `scenario_id` (nullable, only set for roleplay), `vapi_call_id`, `started_at`, `ended_at`, `duration_seconds`, `audio_url` (Supabase Storage path, signed-URL access), `status` (`'active' | 'analyzing' | 'complete' | 'failed'`)

**`transcript_turns`** — turn-by-turn record with timestamps for the interactive transcript UI
- `id`, `session_id`, `speaker` (`'user' | 'ai'`), `text`, `start_ms`, `end_ms`, `turn_index`

**`feedback_reports`** — one per completed session
- `id`, `session_id` (unique), `overall_summary`, `grammar_score`, `pronunciation_score`, `word_choice_score`, `fluency_score`, `vocabulary_score`, `confidence_score` (each 0–100), `success_criteria_met` (nullable bool, only for roleplay), `generated_at`

**`feedback_items`** — individual highlights drawn on the transcript
- `id`, `session_id`, `transcript_turn_id`, `dimension` (one of the six), `severity` (`'minor' | 'major'`), `start_ms`, `end_ms`, `original_text`, `suggested_text`, `explanation`

**`user_skill_aggregates`** — refreshed after each session completes
- `user_id`, `dimension`, `rolling_score`, `session_count`, `updated_at`. Composite PK `(user_id, dimension)`.
- **`rolling_score` formula:** weighted mean of the last 10 session scores in this dimension, with linearly decaying weights `[1.0, 0.9, 0.8, …, 0.1]` (most recent first). If the user has fewer than 10 sessions, use whatever is available with the same descending weights.

**`daily_activity`** — feeds streak and goal tracking
- `user_id`, `date`, `sessions_count`, `minutes_practiced`. Composite PK `(user_id, date)`.

**`user_streak`** — denormalized for fast home-screen reads
- `user_id` (PK), `current_streak`, `longest_streak`, `last_session_date`, `level`.
- **`level` formula:** `floor(total_completed_sessions / 10) + 1`, capped at 50. Simple and predictable in v1; can be replaced with a richer skill-milestone formula later without schema changes.
- **`current_streak`:** consecutive days with at least one completed session. A day with zero completed sessions resets it to 0 the next day.

**`custom_scenarios`** — *(schema reserved for post-launch; not exposed in v1 UI)*
- `id`, `user_id`, scenario fields, `created_at`

**Relationships**
- A user has many sessions. Each session is either free-chat (no scenario) or roleplay (one scenario).
- Each session produces exactly one `feedback_report` and many `transcript_turns` and `feedback_items`.
- `user_skill_aggregates`, `daily_activity`, and `user_streak` are derived state, refreshed by the analysis pipeline after each session.

## 6. Live conversation flow (Vapi-managed)

1. Flutter calls `POST /sessions/start` (Edge Function) with `mode` and `scenario_id`.
2. Backend checks entitlement:
   - If `is_paid = true` → allow; max duration = 1 hour.
   - Else if `trial_sessions_used < 3` → allow; max duration = 5 minutes.
   - Else → return 402 Payment Required; client routes to paywall.
3. Backend creates a `sessions` row (`status='active'`) and provisions a Vapi call configured with:
   - System prompt = scenario's `system_prompt` + persona instructions ("you are an English conversation partner; respond naturally; **do not correct the user mid-conversation**; keep replies concise").
   - Max duration = per the entitlement rule above.
   - STT, LLM, TTS providers configured in Vapi.
   - Webhook target = backend's `/vapi/session-ended` endpoint with HMAC verification.
4. Backend returns Vapi `call_id` + ephemeral room credentials. Flutter joins the WebRTC room via the Vapi SDK.
5. The user converses. Vapi handles streaming, turn-taking, and barge-in.
6. Session ends when: the user taps end, the duration cap is reached, or the AI naturally concludes a roleplay. Vapi finalizes and sends the webhook with audio file URL, transcript with word-level timestamps, and metadata.
7. **Trial counter increment.** If the user was on the trial, `trial_sessions_used` is incremented **inside the `/vapi/session-ended` webhook handler** (i.e., only after the call has happened). This guarantees that failed `/sessions/start` calls and never-connected Vapi rooms do not consume trial credits. The increment is idempotent on the session id.

## 7. Post-session analysis pipeline

Triggered by the `/vapi/session-ended` webhook. The session moves to `status='analyzing'`.

### Steps
1. **Persist raw artifacts.** Save audio to Supabase Storage (signed-URL access). Insert `transcript_turns` rows from Vapi's transcript, preserving `start_ms`/`end_ms`.
2. **LLM analysis pass** (single structured-output call) over user turns only. Prompt asks Claude to return JSON of `feedback_items` covering `grammar`, `word_choice`, `vocabulary`, plus the overall summary and (for roleplays) `success_criteria_met`. Each item carries `transcript_turn_id`, `start_ms`, `end_ms`, `original_text`, `suggested_text`, `explanation`, `severity`.
3. **Filler-word & pace pass** (transcript-only, cheap). Count `um/uh/like/you know` per minute → fluency contribution. Compute words-per-minute and inter-word pause statistics from word timestamps → pace contribution. Emit `feedback_items` for the worst offending segments.
4. **Pronunciation pass** (SpeechAce). Send the user's audio + reference transcript. Receive per-word pronunciation scores. For words below threshold, emit `feedback_items` with phoneme-level explanation. Aggregate to `pronunciation_score`.
5. **Confidence/delivery derivation.** Cheap audio features (RMS energy variance over user turns, hesitation rate from pause patterns, abandoned-phrase count from transcript) combined with an LLM judgment pass on assertiveness of phrasing → `confidence_score`.
6. **Roll up scores.** Each dimension produces a 0–100 score. Persist `feedback_report` + `feedback_items`. Refresh `user_skill_aggregates` (rolling weighted average of last 10 sessions). Increment `daily_activity` and update `user_streak` (level computed from total sessions + skill milestones).
7. **Notify app.** Send a Realtime `session_ready` event so Flutter swaps from "Analyzing…" to the report.

### Parallelism
Steps 2, 3, 4, and 5 are independent and run in parallel. Step 6 awaits all of them; step 7 awaits step 6.

### Per-dimension graceful degradation
If any provider call fails (e.g., SpeechAce times out), the report still ships with the remaining scores and a "_Pronunciation analysis unavailable_" note for the affected dimension. The session is **never** fully blocked by a single provider hiccup. Failed dimensions can be re-run later by an admin tool (out of v1 UI).

### Latency targets
- 5-minute session: under 30 seconds.
- 60-minute session: under 90 seconds.

## 8. Monetization & entitlements

- **Trial:** 3 sessions × 5 minutes each. No credit card required.
- **Hard paywall:** after the 3 trials are used, `/sessions/start` returns 402 and the app routes to the paywall.
- **Paid subscription:** managed by RevenueCat. Webhook (`/webhooks/revenuecat`) flips `is_paid` on the user. Unlocks unlimited sessions up to 1 hour each and the full curated library.
- **Custom scenarios entry-point:** unlocked when `is_paid = true` AND `sessions_count ≥ 30`. v1 reserves the schema and gate; the feature itself is post-launch.

## 9. Flutter app structure

State management: **Riverpod**. Routing: **go_router**. Voice: **Vapi Flutter SDK**. Subscriptions: **RevenueCat SDK**. Realtime updates: **Supabase Flutter SDK**.

Layout:
- `lib/core/` — Supabase client, Vapi wrapper, theming, routing, error reporting.
- `lib/features/auth/` — sign in/up, profile setup.
- `lib/features/home/` — dashboard (streak, level, daily goal, recent sessions, skill chart).
- `lib/features/session/` — scenario picker, in-session voice UI, "analyzing" state.
- `lib/features/feedback/` — interactive transcript, score header, dimension filters.
- `lib/features/progress/` — skill trends, session history.
- `lib/features/paywall/` — trial-exhausted screen, RevenueCat-backed subscription UI.

## 10. Backend services (Supabase Edge Functions)

1. `POST /sessions/start` — entitlement check, create session row, provision Vapi call, return room credentials.
2. `POST /vapi/session-ended` — webhook receiver (HMAC-verified). Persists artifacts and triggers the analysis pipeline.
3. `POST /sessions/:id/finalize` — runs/coordinates the analysis pipeline (steps 1–7 from §7). Idempotent; safe to retry.
4. `POST /scenarios/custom` — *(stubbed; returns 501 in v1, ships post-launch)*.
5. `POST /webhooks/revenuecat` — subscription state changes flip `is_paid`.

The curated scenario data lives as seed rows in Postgres, revisable via normal migrations.

## 11. Security

- All AI provider keys are Supabase Edge Function secrets. Never on-device.
- RLS enabled on every user-scoped table. Users can read/write only rows where `user_id = auth.uid()`. `scenarios` is world-readable.
- Audio storage uses signed URLs scoped to the owning user with a short TTL.
- Vapi room credentials are per-call ephemeral.
- Webhooks (`/vapi/session-ended`, `/webhooks/revenuecat`) verify HMAC signatures.
- Hard daily-minute cap per user (configurable, default high enough to not pinch real use), with a soft warning at 75% to mitigate runaway provider costs.

## 12. Error handling

- **Network drop mid-session** — Vapi attempts reconnect. If unrecoverable, the session ends and analysis runs as normal. UI shows "Connection lost — your session was saved."
- **Vapi outage at start** — `/sessions/start` fails fast with a friendly error. Trial credits are **not** consumed.
- **Analysis pipeline crash** — session moves to `status='failed'`. UI shows "Analysis failed — tap to retry." Retry re-runs the pipeline against the saved audio + transcript (idempotent).
- **Per-dimension provider failure** — covered by §7 graceful degradation.
- **Subscription expiry mid-session** — the in-progress session finishes; the next `/sessions/start` returns 402.
- **Abuse / runaway costs** — hard daily-minute cap per user; soft warning at 75% of cap.

## 13. Testing strategy

- **Flutter** — widget tests for each feature module. Golden tests for the transcript renderer (the visually most complex thing). Integration test for the full happy path against mocked Vapi/Supabase.
- **Backend** — Edge Functions tested with Deno's test runner. The analysis pipeline has a fixture suite: a small set of recorded real-audio sessions + transcripts, runnable against real provider APIs as a separate (costlier) suite.
- **Manual QA gates before each release** — full end-to-end session on a real device, paywall flow, trial-exhaustion flow, dimension-failure simulation.

## 14. v1 scope summary

**In:**
- Auth + profile.
- Curated scenario library (~30 scenarios at launch across categories).
- Free-chat mode and roleplay mode.
- Full 6-dimension feedback (grammar, pronunciation, word choice, fluency, vocabulary, confidence).
- Interactive transcript with inline highlights and tap-to-replay audio.
- Per-skill scores + rolling trend charts.
- Streaks, level, daily goal.
- 3 × 5-minute free trial.
- Hard paywall via RevenueCat subscription.
- 1-hour session cap for paid users.

**Out (deferred):**
- Custom user-authored scenarios (schema and gate reserved; UI ships later).
- Push notifications.
- Social / leaderboard features.
- Offline mode.
- Web companion.
- Voice cloning for the AI partner.
- Analytics dashboards beyond the user's own progress view.

## 15. Open questions for the implementation plan

These do not change the design but will need decisions during planning:
- Vapi vs LiveKit Agents — final pick after a brief spike comparing latency, cost, and Flutter SDK ergonomics.
- LLM choice (Claude vs GPT-4 class) for in-call vs post-session — may be different models.
- SpeechAce vs alternative pronunciation APIs (e.g., ELSA, in-house with Montreal Forced Aligner) — cost/quality trade-off.
- Edge Function timeout vs queued worker — depends on measured analysis-pipeline duration on real fixtures.
