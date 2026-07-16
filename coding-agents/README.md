# coding-agents

Source content that `sync/sync.sh` distributes to `$HOME`. This directory is the
canonical copy — it used to live only in `connect-labo/dev-settings/coding-agents`;
that copy is now considered downstream of this one.

- `AGENTS.md` — synced to `~/.connect0459/coding-agents/AGENTS.md`, then
  symlinked from `~/.claude/CLAUDE.md` and `~/.github/copilot-instructions.md`.
  Written in Japanese intentionally: it is the user's personal instruction
  content, not project documentation.
- `agent-docs/**` — synced to `~/.connect0459/coding-agents/agent-docs/`,
  referenced by `AGENTS.md`. Also kept in Japanese for the same reason.
- `dot-claude/settings.json` — its top-level keys (permissions,
  `enabledPlugins`, `extraKnownMarketplaces`, etc.) are merged into
  `~/.claude/settings.json`; other keys already in that file are left alone.

See `sync/README.md` for how the sync itself works.
