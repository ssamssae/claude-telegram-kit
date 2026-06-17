#!/usr/bin/env bash
# install.sh — copy the hooks into ~/.claude/hooks/ and print next steps.
# Does NOT touch your settings.json (you merge that yourself — see settings.example.json).
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

Done. Final step — merge the hook blocks from:
  $SRC/settings.example.json
into your ~/.claude/settings.json (add to existing arrays; don't overwrite).

Then start a new Claude Code session. The reply-enforcement hook is active
immediately; the device emoji prefix shows up on the next session start.

Requires: jq (the hooks parse the transcript with it).
EOF
