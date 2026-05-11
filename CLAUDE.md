# Project Memory

## Workflow Preferences (all sessions)
- **Always push to remote after every commit.** Immediately run `git push` after each `git commit`.
- Never create a PR unless explicitly asked.

## Web-session-only context (Claude Code web)
These items apply **only** to Claude Code web sessions (where each session is ephemeral and re-clones the plugin). **Local Claude Code CLI sessions on the user's machine ignore this section entirely** — the plugin is already installed locally, and commits go to `main` (or whichever branch the user is on), not to the web-session brainstorm branch.

- Web-session development branch (historical): `claude/brainstorm-superpowers-ideas-gBahf`
- Web-session PR #1 (already merged into `main` — kept here only as historical anchor for re-runs): https://github.com/Bhaskar422/superpowers-claude-test/pull/1

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

**Web sessions only:** installed via SessionStart hook (`.claude/hooks/session-start.sh`), which clones `obra/superpowers` into `.superpowers/` (gitignored) and links skills into `~/.claude/skills/` each session.

**Local sessions:** the plugin is already installed under `~/.claude/plugins/cache/claude-plugins-official/superpowers/...`. The SessionStart hook is not run on local; ignore it.

When superpowers skills are available (both web and local), use them:
- `brainstorming` skill before starting any new feature
- `test-driven-development` skill when writing code (RED-GREEN-REFACTOR)
- `writing-plans` skill to break work into 2-5 min tasks
- `subagent-driven-development` skill to execute a multi-task plan with a fresh subagent per task
