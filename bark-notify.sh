#!/usr/bin/env bash
# Claude Code → Bark notification hook
#
# Pushes mobile notifications via Bark when Claude needs your attention.
#   title = "Claude Code · <project name>"
#   body  = last assistant message snippet from session transcript
#
# Setup: see README.md

BARK_KEY="${BARK_KEY:-your_bark_key_here}"
BARK_HOST="${BARK_HOST:-https://api.day.app}"
ICON="${BARK_ICON:-https://claude.ai/favicon.ico}"
MAX_BODY="${BARK_MAX_BODY:-200}"

data=$(cat)

proj=$(printf '%s' "$data" | jq -r '.cwd // "" | split("/") | last // empty' 2>/dev/null)
[ -z "$proj" ] && proj="Claude"

tx=$(printf '%s' "$data" | jq -r '.transcript_path // ""' 2>/dev/null)
body=""
if [ -n "$tx" ] && [ -f "$tx" ]; then
  body=$(tail -n 500 "$tx" 2>/dev/null \
    | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null \
    | tail -n 1 \
    | head -c "$MAX_BODY")
fi
if [ -z "$body" ]; then
  body=$(printf '%s' "$data" | jq -r '.message // "Notification"' 2>/dev/null)
  [ -z "$body" ] && body="Notification"
fi

title_enc=$(printf '%s' "Claude Code · $proj" | jq -sRr @uri)
body_enc=$(printf '%s' "$body" | jq -sRr @uri)

curl -s "${BARK_HOST}/${BARK_KEY}/${title_enc}/${body_enc}?icon=${ICON}" > /dev/null 2>&1 &
exit 0
