#!/usr/bin/env bash
# telegram-ui-guard.sh — PreToolUse hook.
# Matcher: AskUserQuestion|ExitPlanMode|EnterPlanMode
#
# These tools render an interactive box in the terminal. When the conversation
# is driven from Telegram, that box never appears on the user's phone — so the
# assistant freezes waiting for input that can never arrive.
#
# This hook blocks those tools (exit 2) when the current turn originates from
# Telegram, forcing the model to ask its question as plain text via the reply
# tool instead (e.g. "(a) X / (b) Y / (c) Z — which one?").
#
# Registered as a PreToolUse hook (see settings.example.json).

set -uo pipefail

input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
  AskUserQuestion|ExitPlanMode|EnterPlanMode) ;;
  *) exit 0 ;;
esac

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
{ [ -z "$transcript" ] || [ ! -f "$transcript" ]; } && exit 0

# Is the last real user prompt from Telegram? (same detection as reply-check)
last_user=$(jq -c 'select(.type=="user" and (.message.content | type == "string"))' "$transcript" 2>/dev/null | tail -1)
if printf '%s' "$last_user" | grep -q 'plugin:telegram:telegram'; then
  echo "Blocked: $tool can't be used in a Telegram-originated turn — the option/plan box is invisible on the user's phone and the session would hang. Ask your question as plain text in the reply tool body instead (e.g. '(a) X / (b) Y / (c) Z — which?')." >&2
  exit 2
fi

exit 0
