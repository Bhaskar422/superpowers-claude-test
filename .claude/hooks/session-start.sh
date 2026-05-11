#!/bin/bash
set -euo pipefail

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SUPERPOWERS_DIR="$REPO_DIR/.superpowers"
MANIFEST="$REPO_DIR/.claude/required-skills.txt"

# Install step: only run in remote/web sessions.
# Locally, superpowers is expected to be installed via `/plugin install superpowers`.
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  if [ ! -d "$SUPERPOWERS_DIR/.git" ]; then
    echo "Cloning superpowers..."
    git clone --depth=1 https://github.com/obra/superpowers "$SUPERPOWERS_DIR" 2>&1
  else
    echo "Updating superpowers..."
    git -C "$SUPERPOWERS_DIR" pull --ff-only 2>&1 || true
  fi

  mkdir -p "$HOME/.claude/skills"
  for skill_dir in "$SUPERPOWERS_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$HOME/.claude/skills/$skill_name"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
      ln -sf "$skill_dir" "$target"
    fi
  done
  echo "Superpowers ready: $(ls "$SUPERPOWERS_DIR/skills/" | wc -l) skills linked"
fi

# Parity check: always run, in both environments.
# Warns if any required skill is missing from ~/.claude/skills/.
if [ -f "$MANIFEST" ]; then
  missing=()
  while IFS= read -r line; do
    skill="${line%%#*}"
    skill="${skill// /}"
    [ -z "$skill" ] && continue
    [ -e "$HOME/.claude/skills/$skill" ] || missing+=("$skill")
  done < "$MANIFEST"

  if [ ${#missing[@]} -gt 0 ]; then
    echo ""
    echo "WARNING: ${#missing[@]} required skill(s) missing: ${missing[*]}"
    if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
      echo "  Web session: the bootstrap hook may have failed. Check the clone output above."
    else
      echo "  Local session: install superpowers via '/plugin install superpowers'"
      echo "  (first: /plugin marketplace add obra/superpowers)"
    fi
    echo ""
  fi
fi
