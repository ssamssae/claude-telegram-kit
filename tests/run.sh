#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

assert_empty() {
  local value="$1"
  local label="$2"
  if [ -n "$value" ]; then
    fail "expected empty $label, got: $value"
  fi
}

"$ROOT/scripts/validate-plugin.sh"

telegram_no_reply="$TMP_ROOT/telegram-no-reply.jsonl"
cat > "$telegram_no_reply" <<'JSONL'
{"type":"user","timestamp":"2026-06-18T00:00:00Z","message":{"content":"<channel source=\"plugin:telegram:telegram\">hello</channel>"}}
{"type":"assistant","timestamp":"2026-06-18T00:00:01Z","message":{"content":[{"type":"text","text":"terminal only"}]}}
JSONL

reply_check_input="$(jq -nc --arg path "$telegram_no_reply" '{transcript_path:$path,stop_hook_active:false}')"
reply_check_out="$(printf '%s' "$reply_check_input" | "$ROOT/hooks/telegram-reply-check.sh")"
assert_contains "$reply_check_out" '"decision":"block"'

telegram_with_reply="$TMP_ROOT/telegram-with-reply.jsonl"
cat > "$telegram_with_reply" <<'JSONL'
{"type":"user","timestamp":"2026-06-18T00:00:00Z","message":{"content":"<channel source=\"plugin:telegram:telegram\">hello</channel>"}}
{"type":"assistant","timestamp":"2026-06-18T00:00:01Z","message":{"content":[{"type":"tool_use","name":"mcp__plugin_telegram_telegram__reply","input":{"text":"ok"}}]}}
JSONL

reply_check_input="$(jq -nc --arg path "$telegram_with_reply" '{transcript_path:$path,stop_hook_active:false}')"
reply_check_out="$(printf '%s' "$reply_check_input" | "$ROOT/hooks/telegram-reply-check.sh")"
assert_empty "$reply_check_out" "reply-check output after reply tool use"

non_telegram="$TMP_ROOT/non-telegram.jsonl"
cat > "$non_telegram" <<'JSONL'
{"type":"user","timestamp":"2026-06-18T00:00:00Z","message":{"content":"hello from terminal"}}
JSONL

guard_input="$(jq -nc --arg path "$telegram_no_reply" '{tool_name:"AskUserQuestion",transcript_path:$path}')"
set +e
guard_out="$(printf '%s' "$guard_input" | "$ROOT/hooks/telegram-ui-guard.sh" 2>&1)"
guard_status=$?
set -e
[ "$guard_status" -eq 2 ] || fail "expected telegram-ui-guard to exit 2, got $guard_status"
assert_contains "$guard_out" "Blocked: AskUserQuestion"

guard_input="$(jq -nc --arg path "$non_telegram" '{tool_name:"AskUserQuestion",transcript_path:$path}')"
guard_out="$(printf '%s' "$guard_input" | "$ROOT/hooks/telegram-ui-guard.sh" 2>&1)"
assert_empty "$guard_out" "ui-guard output for non-Telegram turn"

devices_conf="$TMP_ROOT/devices.conf"
printf '*|T|test-node\n' > "$devices_conf"
device_out="$(DEVICES_CONF="$devices_conf" "$ROOT/hooks/session-device-id.sh")"
assert_contains "$device_out" "[device-id] T test-node"

device_out="$(TELEGRAM_DEVICE_EMOJI=E TELEGRAM_DEVICE_LABEL=env-node "$ROOT/hooks/session-device-id.sh")"
assert_contains "$device_out" "[device-id] E env-node"

echo "hook behavior tests passed"
