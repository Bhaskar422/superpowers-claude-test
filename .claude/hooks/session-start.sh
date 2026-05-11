#!/bin/bash
set -euo pipefail

# Only run in remote/web sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SUPERPOWERS_DIR="$REPO_DIR/.superpowers"

# Clone superpowers if not present
if [ ! -d "$SUPERPOWERS_DIR/.git" ]; then
  echo "Cloning superpowers..."
  git clone --depth=1 https://github.com/obra/superpowers "$SUPERPOWERS_DIR" 2>&1
else
  echo "Updating superpowers..."
  git -C "$SUPERPOWERS_DIR" pull --ff-only 2>&1 || true
fi

# Wire superpowers skills into ~/.claude/skills/
mkdir -p "$HOME/.claude/skills"
for skill_dir in "$SUPERPOWERS_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$HOME/.claude/skills/$skill_name"
  # Overwrite stale symlinks but don't clobber real dirs
  if [ -L "$target" ] || [ ! -e "$target" ]; then
    ln -sf "$skill_dir" "$target"
  fi
done

echo "Superpowers ready: $(ls "$SUPERPOWERS_DIR/skills/" | wc -l) skills linked into ~/.claude/skills/"
