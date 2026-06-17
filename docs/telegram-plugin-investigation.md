# Telegram MCP Plugin Investigation

This machine's Telegram bridge is the official `telegram` plugin from the
`claude-plugins-official` marketplace, not code owned by this repository.

Local findings:

- Marketplace: `claude-plugins-official`
- Marketplace source: `anthropics/claude-plugins-official`
- Installed plugin: `telegram@claude-plugins-official`
- Installed version observed: `0.0.6`
- Cached plugin path pattern: `~/.claude/plugins/cache/claude-plugins-official/telegram/<version>`
- Plugin manifest: `.claude-plugin/plugin.json`
- MCP server definition: `.mcp.json`
- MCP server command: `bun run --cwd ${CLAUDE_PLUGIN_ROOT} --shell=bun --silent start`
- Package license observed in the cached plugin: `Apache-2.0`

Packaging decision:

This repository does not vendor or copy the Telegram bridge source. The official
Telegram plugin owns the MCP server, bot token storage, pairing flow, and access
policy. This repository is packaged as a separate Claude Code plugin that
declares only the safety hooks.

Fresh installs therefore use two explicit steps:

1. Install and configure `telegram@claude-plugins-official`.
2. Install `claude-telegram-kit` from this private marketplace/repository.

That keeps this repository small, avoids duplicating upstream plugin code, and
lets the Telegram bridge continue to receive marketplace updates independently.
