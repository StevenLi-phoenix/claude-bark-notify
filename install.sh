#!/usr/bin/env bash
# One-line installer for claude-bark-notify
# Usage: BARK_KEY=your_key bash install.sh

set -euo pipefail

BARK_KEY="${BARK_KEY:-}"
if [ -z "$BARK_KEY" ]; then
  echo "Usage: BARK_KEY=your_key bash install.sh" >&2
  exit 1
fi

SCRIPT_DIR="$HOME/.claude/scripts"
SCRIPT_PATH="$SCRIPT_DIR/bark-notify.sh"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$SCRIPT_DIR"

# Write script with key substituted
sed "s/your_bark_key_here/$BARK_KEY/" "$(dirname "$0")/bark-notify.sh" > "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo "✓ Installed $SCRIPT_PATH"

# Patch settings.json Notification hook if jq available
if ! command -v jq &> /dev/null; then
  echo "jq not found — add hook manually (see README)"
  exit 0
fi

if [ ! -f "$SETTINGS" ]; then
  echo "~/.claude/settings.json not found — add hook manually (see README)"
  exit 0
fi

# Check if bark-notify is already wired
if jq -e '.hooks.Notification[]?.hooks[]? | select(.command | contains("bark-notify"))' "$SETTINGS" > /dev/null 2>&1; then
  echo "✓ Hook already present in settings.json, skipping"
  exit 0
fi

# Inject hook via jq
cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
tmp=$(mktemp)
jq --arg cmd "$SCRIPT_PATH" '
  .hooks.Notification = ([{"matcher":"","hooks":[{"type":"command","command":$cmd}]}]
    + (.hooks.Notification // []))
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

echo "✓ Notification hook added to ~/.claude/settings.json"
echo "Reload Claude Code for changes to take effect."
