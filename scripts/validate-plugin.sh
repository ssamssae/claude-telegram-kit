#!/usr/bin/env bash
# Validate the Claude Code plugin packaging without requiring Telegram secrets.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

need jq

jq empty "$ROOT/.claude-plugin/plugin.json"
jq empty "$ROOT/hooks/hooks.json"
jq empty "$ROOT/settings.example.json"

for hook in \
  "$ROOT/hooks/session-device-id.sh" \
  "$ROOT/hooks/telegram-reply-check.sh" \
  "$ROOT/hooks/telegram-ui-guard.sh"; do
  if [ ! -x "$hook" ]; then
    echo "hook is not executable: $hook" >&2
    exit 1
  fi
done

tmp_hooks="$(mktemp)"
trap 'rm -f "$tmp_hooks"' EXIT
jq '.hooks' "$ROOT/hooks/hooks.json" > "$tmp_hooks"

hook_validator="$HOME/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/hook-development/scripts/validate-hook-schema.sh"
if [ -x "$hook_validator" ]; then
  "$hook_validator" "$tmp_hooks"
else
  jq -e '
    type == "object" and
    all(.[]; type == "array") and
    (
      [
        .. | objects
        | select(.type? == "command")
        | .command
      ] | length
    ) > 0
  ' "$tmp_hooks" >/dev/null
fi

jq -r '
  .. | objects
  | select(.type? == "command")
  | .command
' "$ROOT/hooks/hooks.json" | while IFS= read -r raw_command; do
  command="${raw_command//\$\{CLAUDE_PLUGIN_ROOT\}/$ROOT}"
  read -r runner target _rest <<< "$command"
  case "$runner" in
    bash|sh) hook_path="$target" ;;
    *) hook_path="$runner" ;;
  esac
  if [[ "$hook_path" == \~/* ]]; then
    hook_path="$HOME/${hook_path#\~/}"
  fi
  if [ ! -f "$hook_path" ]; then
    echo "hook command does not resolve to a file: $raw_command" >&2
    exit 1
  fi
done

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$ROOT/.claude-plugin/plugin.json" --strict
  claude plugin validate "$ROOT/.claude-plugin/marketplace.json" --strict
else
  echo "skipping Claude plugin validator: claude command not found" >&2
fi

echo "plugin packaging validation passed"
