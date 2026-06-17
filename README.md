# claude-telegram-kit

**Run Claude Code from your phone over Telegram — and make sure it actually answers.**

If you drive [Claude Code](https://claude.com/claude-code) from a Telegram bot
(via an MCP plugin), you've hit this: Claude "replies" in the terminal, the turn
ends, and **nothing shows up on your phone.** Your terminal output never reaches
Telegram. You're left staring at a silent chat.

This kit is three small, dependency-light **hooks** that fix the rough edges of a
Telegram-driven Claude Code setup:

| Hook | What it does |
|------|--------------|
| 🔁 **`telegram-reply-check.sh`** | If a turn started from Telegram but Claude never called the reply tool, **block the stop and force it to reply.** No more silent terminal-only answers. This is the one you came for. |
| 🚧 **`telegram-ui-guard.sh`** | Blocks `AskUserQuestion` / `ExitPlanMode` / `EnterPlanMode` during a Telegram turn — those render an interactive box that's **invisible on your phone**, so the session would hang forever waiting for input. Forces Claude to ask in plain text instead. |
| 🏷️ **`session-device-id.sh`** | Optional. Run Claude Code on several machines? This prefixes each reply with a per-machine emoji (💻 / 🖥 / 🏭 …) so you can tell at a glance which box answered. |

It does **not** include a Telegram bridge — use any Telegram MCP plugin for that
(this kit just makes the hooks around it sane). No bot token ever goes into this
repo.

---

## Why hooks and not just a prompt rule?

You can write "always reply via Telegram" in your `CLAUDE.md`. It works ~95% of
the time. The other 5% — exactly when you're away from the keyboard and relying
on it — Claude forgets, answers in the terminal, and you get nothing. A **Stop
hook is deterministic**: it inspects the transcript and refuses to let the turn
end until the reply actually went out. Forcing functions beat reminders.

---

## Install

```bash
git clone https://github.com/<you>/claude-telegram-kit.git
cd claude-telegram-kit
./install.sh        # copies hooks → ~/.claude/hooks/
```

Then merge the hook blocks from [`settings.example.json`](settings.example.json)
into your `~/.claude/settings.json` (add to the existing arrays; don't overwrite
the file). Start a new Claude Code session — done.

**Requires:** `jq` (the hooks parse the session transcript with it) and any
Telegram MCP plugin wired into Claude Code.

### If your reply tool has a different name

The hooks default to the tool name `mcp__plugin_telegram_telegram__reply`. If
your plugin exposes it differently, set `TELEGRAM_REPLY_TOOL` in your environment
(see [`telegram.env.example`](telegram.env.example)).

---

## How the reply-enforcement hook works

1. On every `Stop`, it reads the session transcript.
2. Finds the **last real user prompt** and checks whether it carried the
   `plugin:telegram:telegram` channel marker (i.e. it came from Telegram).
3. If so, it counts how many times the reply tool was called *after* that
   prompt's timestamp.
4. Zero calls → `{"decision":"block", ...}` with a message telling Claude to
   reply right now. One or more calls → let the turn end.

Every failure path exits `0`, so a broken hook can never wedge your session.
There's also a `stop_hook_active` guard to prevent infinite block loops.

---

## Multi-machine emoji prefixes (optional)

If you run Claude Code on more than one machine, edit `~/.claude/hooks/devices.conf`
(created from [`devices.conf.example`](hooks/devices.conf.example)):

```
my-laptop*|💻|laptop
my-desktop*|🖥|desktop
my-server*|🏭|server
*|📱|unknown
```

Each line is `hostname_glob|emoji|label`; the first glob matching your `hostname`
wins. Single-machine users can skip the file and just set
`TELEGRAM_DEVICE_EMOJI` / `TELEGRAM_DEVICE_LABEL` in their environment.

The `SessionStart` hook then injects a line like
`[device-id] 💻 laptop | hostname=...` into the first turn so Claude knows which
emoji to lead its replies with.

---

## Security

- This kit **never needs your Telegram bot token.** It lives in your MCP
  plugin's own config. Don't put it here.
- `telegram.env` and `hooks/devices.conf` are gitignored so your local edits
  don't get committed.

## License

MIT — see [LICENSE](LICENSE).
