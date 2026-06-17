#!/usr/bin/env bash
# telegram-reply-check.sh — Stop hook.
#
# If the last real user prompt came from Telegram (i.e. the message contained
# the `plugin:telegram:telegram` channel marker) but THIS assistant turn never
# called the Telegram `reply` tool, block the stop and tell the model to reply.
#
# Why: plain terminal output never reaches the user's phone. Without this guard
# Claude will happily "answer" in the terminal and the Telegram user sees silence.
# This is the core forcing function of the kit.
#
# Registered as a Stop hook (see settings.example.json). All failures are
# swallowed (exit 0) so a broken hook never wedges your session.

set -u
LOG="${TMPDIR:-/tmp}/claude-telegram-reply-check.log"
log() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }

# Name of the Telegram reply tool. Override via env if your plugin differs.
REPLY_TOOL="${TELEGRAM_REPLY_TOOL:-mcp__plugin_telegram_telegram__reply}"

input=$(cat)

# Already blocked once this turn — don't loop forever.
if echo "$input" | grep -q '"stop_hook_active":true'; then
  log "skip: stop_hook_active=true"
  exit 0
fi

transcript=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  log "skip: no transcript ($transcript)"
  exit 0
fi

# Last *real* user prompt (content is a string; tool_results are arrays, skip them).
last_user=$(jq -c 'select(.type=="user" and (.message.content | type == "string"))' "$transcript" 2>/dev/null | tail -1)
if [ -z "$last_user" ]; then
  log "skip: no real user prompt"
  exit 0
fi

# Was it from Telegram?
if ! echo "$last_user" | grep -q 'plugin:telegram:telegram'; then
  log "skip: last user not from telegram"
  exit 0
fi

last_ts=$(echo "$last_user" | jq -r '.timestamp // empty' 2>/dev/null)
if [ -z "$last_ts" ]; then
  log "skip: no timestamp on last user"
  exit 0
fi

# Did any assistant message after that timestamp call the reply tool?
reply_count=$(jq -sr --arg ts "$last_ts" --arg tool "$REPLY_TOOL" '
  [.[] | select(.type=="assistant" and .timestamp > $ts)
       | .message.content[]?
       | select(.type=="tool_use" and .name==$tool)
  ] | length
' "$transcript" 2>/dev/null)

if [ "${reply_count:-0}" -gt 0 ]; then
  log "ok: reply tool called $reply_count time(s)"
  exit 0
fi

log "BLOCK: telegram-origin at $last_ts, 0 reply tool calls"

cat <<JSON
{"decision":"block","reason":"The last message came from Telegram (<channel source=\"plugin:telegram:telegram\">) but you did not call the $REPLY_TOOL tool this turn. Terminal-only output is invisible to the Telegram user. Send your answer now via the reply tool, passing back the chat_id from the inbound message. Long answers are fine — put the whole thing in the reply body."}
JSON
