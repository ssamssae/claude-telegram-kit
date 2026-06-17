#!/usr/bin/env bash
# session-device-id.sh — SessionStart hook.
#
# Injects a "which machine am I on" line into the first turn's context, and tells
# the model to start every Telegram reply with a 1-char device emoji prefix.
#
# This is the multi-machine feature: if you run Claude Code on several boxes that
# all talk to you over Telegram, the emoji prefix lets you tell at a glance which
# machine answered. Single-machine users can ignore the config and just set
# TELEGRAM_DEVICE_EMOJI / TELEGRAM_DEVICE_LABEL once (see below).
#
# Resolution order for this machine's emoji + label:
#   1. Env vars TELEGRAM_DEVICE_EMOJI / TELEGRAM_DEVICE_LABEL (simplest, per-machine).
#   2. devices.conf — lines of "hostname_glob|emoji|label" matched against `hostname`.
#   3. Fallback: 📱 / unknown.
#
# Registered as a SessionStart hook (see settings.example.json).

EMOJI="${TELEGRAM_DEVICE_EMOJI:-}"
LABEL="${TELEGRAM_DEVICE_LABEL:-}"
HOST=$(hostname 2>/dev/null || echo unknown)

# devices.conf lives next to this script by default; override with DEVICES_CONF.
CONF="${DEVICES_CONF:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/devices.conf}"

if [ -z "$EMOJI" ] && [ -f "$CONF" ]; then
  while IFS='|' read -r pattern emoji label; do
    case "$pattern" in ''|\#*) continue ;; esac
    # shellcheck disable=SC2254
    case "$HOST" in
      $pattern) EMOJI="$emoji"; LABEL="$label"; break ;;
    esac
  done < "$CONF"
fi

[ -z "$EMOJI" ] && EMOJI="📱"
[ -z "$LABEL" ] && LABEL="unknown"

echo "[device-id] $EMOJI $LABEL | hostname=$HOST"
echo "[device-id] Start every Telegram reply with this 1-char emoji: $EMOJI"
