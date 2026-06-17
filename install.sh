#!/usr/bin/env bash
# install.sh — legacy manual install that copies hooks into ~/.claude/hooks/.
# The preferred new-machine flow is the Claude Code plugin install in README.md.
# This script does NOT touch settings.json.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"

mkdir -p "$DEST"
for f in telegram-reply-check.sh telegram-ui-guard.sh session-device-id.sh; do
  cp "$SRC/hooks/$f" "$DEST/$f"
  chmod +x "$DEST/$f"
  echo "installed: $DEST/$f"
done

if [ ! -f "$DEST/devices.conf" ]; then
  cp "$SRC/hooks/devices.conf.example" "$DEST/devices.conf"
  echo "created:   $DEST/devices.conf  (edit this for multi-machine emoji prefixes)"
fi

cat <<EOF

Done. This was the legacy manual install.

Preferred plugin install for new machines:
  cd $SRC
  ./scripts/validate-plugin.sh
  claude plugin marketplace add $SRC
  claude plugin install claude-telegram-kit@claude-telegram-kit --scope user

Manual-install final step: merge the hook blocks from:
  $SRC/settings.example.json
into your ~/.claude/settings.json (add to existing arrays; don't overwrite).

Then start a new Claude Code session. The reply-enforcement hook is active
immediately; the device emoji prefix shows up on the next session start.

Requires: jq (the hooks parse the transcript with it). The Telegram MCP bridge
is provided by telegram@claude-plugins-official.
EOF
