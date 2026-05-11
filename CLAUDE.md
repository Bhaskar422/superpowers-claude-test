# Project Memory

## Workflow Preferences
- **Always push to remote after every change.** After committing, immediately run `git push -u origin <branch>`.
- Development branch: `claude/brainstorm-superpowers-ideas-gBahf`
- Active PR: https://github.com/Bhaskar422/superpowers-claude-test/pull/1 — pushing to the branch updates it automatically.
- Never create a PR unless explicitly asked.

## Project: English Speaking Coach
A mobile app for improving spoken English via AI voice conversations with post-session feedback.

**Key docs:**
- Design spec: `docs/superpowers/specs/2026-05-10-english-speaking-coach-design.md`
- Foundation plan (Plan 1): `docs/superpowers/plans/2026-05-11-plan-1-foundation.md`

**Tech stack:**
- Mobile: Flutter (Dart 3.x), Riverpod, go_router
- Backend: Supabase (Postgres + Auth + RLS + Edge Functions)
- Voice: Vapi (WebRTC + STT + LLM + TTS)
- Pronunciation: SpeechAce
- Subscriptions: RevenueCat
- AI: Claude (in-call + post-session analysis)

**Plan 1 goal:** Auth + profile setup + bottom-nav shell. No AI yet. All 10 DB tables ship in this plan.

## Superpowers Plugin
Installed via SessionStart hook (`.claude/hooks/session-start.sh`). Clones `obra/superpowers` into `.superpowers/` (gitignored) and links skills into `~/.claude/skills/` each web session.

When superpowers skills are available, use them:
- `brainstorming` skill before starting any new feature
- `test-driven-development` skill when writing code (RED-GREEN-REFACTOR)
- `writing-plans` skill to break work into 2-5 min tasks
