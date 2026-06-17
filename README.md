# claude-telegram-kit

**Run Claude Code from your phone over Telegram, and make sure it actually answers.**

This repository packages three dependency-light Claude Code hooks as a
Claude Code plugin:

| Hook | What it does |
|------|--------------|
| 🔁 `telegram-reply-check.sh` | If a turn started from Telegram but Claude never called the reply tool, block the stop and force it to reply. |
| 🚧 `telegram-ui-guard.sh` | Blocks `AskUserQuestion` / `ExitPlanMode` / `EnterPlanMode` during a Telegram turn, because those terminal UI boxes are invisible from Telegram. |
| 🏷️ `session-device-id.sh` | Optional. Adds a per-machine prefix instruction so replies can identify which machine answered. |

The Telegram MCP bridge is intentionally **not** copied into this repo. Use the
official `telegram@claude-plugins-official` channel plugin for bot token storage,
pairing, allowlists, and the MCP server. This kit installs the hooks around that
bridge.

## Fresh Machine Install

### 1. Install prerequisites

```bash
command -v jq >/dev/null || brew install jq
command -v bun >/dev/null || curl -fsSL https://bun.sh/install | bash
```

### 2. Install the official Telegram channel plugin

In Claude Code:

```text
/plugin install telegram@claude-plugins-official
/reload-plugins
/telegram:configure <BOT_TOKEN_FROM_BOTFATHER>
```

Then message the bot from Telegram and complete the pairing flow in Claude Code:

```text
/telegram:access pair <PAIRING_CODE>
/telegram:access policy allowlist
```

### 3. Install this hook kit as a Claude Code plugin

From a shell on the new machine:

```bash
git clone git@github.com:ssamssae/claude-telegram-kit.git ~/claude-telegram-kit
cd ~/claude-telegram-kit
./scripts/validate-plugin.sh
claude plugin marketplace add ~/claude-telegram-kit
claude plugin install claude-telegram-kit@claude-telegram-kit --scope user
```

Start Claude Code with the Telegram channel enabled:

```bash
claude --channels plugin:telegram@claude-plugins-official
```

After install, Claude Code loads `hooks/hooks.json` from this plugin. The hook
commands use `${CLAUDE_PLUGIN_ROOT}`, so they keep working from the plugin cache
instead of depending on `~/.claude/hooks`.

### 4. Optional device prefixes

For a plugin install, keep local per-machine labels outside the plugin cache:

```bash
mkdir -p ~/.claude/claude-telegram-kit
cp ~/claude-telegram-kit/hooks/devices.conf.example ~/.claude/claude-telegram-kit/devices.conf
```

Edit `~/.claude/claude-telegram-kit/devices.conf`:

```text
my-laptop*|💻|laptop
my-desktop*|🖥|desktop
my-server*|🏭|server
*|📱|unknown
```

Each line is `hostname_glob|emoji|label`; the first glob matching `hostname`
wins. Single-machine users can skip the file and set
`TELEGRAM_DEVICE_EMOJI` / `TELEGRAM_DEVICE_LABEL` in their environment.

## Legacy Manual Install

The plugin install above is preferred for new machines. The old manual hook copy
flow is still supported:

```bash
git clone git@github.com:ssamssae/claude-telegram-kit.git
cd claude-telegram-kit
./install.sh
```

Then merge the hook blocks from [`settings.example.json`](settings.example.json)
into `~/.claude/settings.json`.

## Reply Tool Name

The hooks default to the official Telegram channel reply tool:

```text
mcp__plugin_telegram_telegram__reply
```

If your Telegram plugin exposes a different reply tool, set
`TELEGRAM_REPLY_TOOL` in your environment. See
[`telegram.env.example`](telegram.env.example).

## How Reply Enforcement Works

1. On every `Stop`, the hook reads the session transcript.
2. It finds the last real user prompt and checks for the
   `plugin:telegram:telegram` channel marker.
3. It counts reply-tool calls after that prompt.
4. Zero calls blocks the stop and asks Claude to reply through Telegram. One or
   more calls let the turn end.

Failure paths exit `0`, so a broken hook should not wedge a session. The Stop
hook also honors `stop_hook_active` to avoid block loops.

## Validation

Run the local validation suite before committing:

```bash
./tests/run.sh
```

`tests/run.sh` validates the plugin manifest, hook schema, hook path resolution,
and the core behavior of all three hooks without using Telegram secrets. Also
run the directive-provided forbidden-literal scan from the repository root before
committing.

## Security

- This kit never needs your Telegram bot token or chat identifier.
- The official Telegram plugin stores its own channel configuration.
- Keep local per-machine labels in `~/.claude/claude-telegram-kit/devices.conf`
  or environment variables, not in this repository.
- `telegram.env` and `hooks/devices.conf` are gitignored for legacy manual
  installs.

## License

MIT. See [LICENSE](LICENSE).
