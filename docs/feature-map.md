# Verification paths

Run `./tests/run.sh` from a checkout with Bash and jq. When the Claude Code CLI
is present, the suite also runs its strict plugin and marketplace validators.

| Behavior | Exercise | Expected evidence |
| --- | --- | --- |
| Plugin packaging | Validate both `.claude-plugin` manifests | `telegram-reply-kit` accepted; no reserved-name error |
| Paths containing spaces | Copy plugin files under a temporary path with spaces; execute all three registered commands | Device prefix emitted, omitted reply blocked, Telegram-only question blocked |
| Omitted reply | Synthetic Telegram-origin turn with no reply-tool call | Stop returns a block decision |
| Reply attempted | Synthetic turn containing a matching reply-tool call | Stop returns no block; this is not delivery proof |
| UI guard scope | Synthetic Telegram and ordinary terminal turns | Telegram question blocked; terminal question permitted |
| Local device label | Fixture configuration and environment overrides | Expected label emitted |

The suite uses synthetic transcripts and task-owned temporary files. It does not
install a plugin, reload a live session, send Telegram messages, or verify receipt.
For a live installation, separately confirm the intended plugin is active in the
target session and perform an authorized end-to-end check. Existing 0.1.0
installations need an explicit migration to the new plugin ID; see the README.
