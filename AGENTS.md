# AGENTS.md / CLAUDE.md

## Primary Directive

- Think in English. For user interaction language, follow the setting in the user's global `AGENTS.md`, `CLAUDE.md`, or `CLAUDE.local.md`.

## Language Convention

This project is intended for public release. All of the following must be written in **English**:

- Commit messages
- Documentation (including `AGENTS.md`, `README.md`, and any `scripts/sync-agents/README.md`-style subdirectory docs)

Exception: `home/dot_agents/AGENTS.md` and `home/dot_agents/agent-docs/**` are not project documentation — they are the user's personal instruction content for coding agents, distributed as-is by `scripts/sync-agents/sync-agents.sh`, and are kept in Japanese intentionally.

## Project Overview

This is a personal dotfiles repository. `home/` is the canonical source of everything that ends up under `$HOME`: shell rc files under their real names (`home/.bashrc`, `home/.bash_profile`, `home/.bash_aliases`), plus `dot_`-prefixed directories for content that lands one level deeper (`home/dot_config/git/ignore` → `~/.config/git/ignore`, `home/dot_config/Code/User/settings.json` → symlinked to the platform's VS Code user settings path (`~/Library/Application Support/Code/User/settings.json` on macOS, `~/.config/Code/User/settings.json` on Linux), `home/dot_claude/settings.json` → merged into `~/.claude/settings.json`, `home/dot_agents/` → distributed into `~/.agents/` — `AGENTS.md` at the top level, `agent-docs/` as a subdirectory). No GNU Stow or chezmoi. See the root `README.md` for the actual file inventory.

`scripts/` holds every automation script this repo ships, each paired with its own tests (`scripts/tests/` for `setup.sh`). `scripts/setup.sh` symlinks the plain dotfiles from `home/` into `$HOME`, then delegates to `scripts/sync-agents/sync-agents.sh` for the coding-agent config distribution: it copies `home/dot_agents/AGENTS.md` into `~/.agents/AGENTS.md` and syncs `home/dot_agents/agent-docs/**` into `~/.agents/agent-docs/`, symlinks `~/.claude/CLAUDE.md` and `~/.github/copilot-instructions.md` to the former, and merges `home/dot_claude/settings.json` into `~/.claude/settings.json` — see `scripts/sync-agents/README.md` for details.

## Conventions

### Directory naming

- A directory gets the `dot_foo` prefix (underscore, not a literal leading dot) when its contents are symlinked, physically copied, or merged onto a real path one level under `$HOME` — as `home/dot_claude/settings.json` is, via a merge into `~/.claude/settings.json`, and `home/dot_agents/` is, via `scripts/sync-agents/sync-agents.sh` distributing it into `~/.agents/` and symlinking `~/.agents/AGENTS.md` into `~/.claude/CLAUDE.md`.
- A file that is itself the direct symlink target keeps its real dotted name instead (e.g. `home/.bashrc`, not `home/dot_bashrc`).
- Content that is not itself a hidden-path target (tooling, documentation, source scripts) uses a plain name — do not prefix it with `dot_`.

### Shell scripts

- Target bash 3.2 compatibility (macOS's stock `/bin/bash`) — no bash 4+ features (associative arrays, `mapfile`, etc.).
- Every script under `lib/` must pass `shellcheck` with no warnings.
- Prefer POSIX/portable tools already present on macOS (`find`, `shasum`, `awk`) over adding new runtime dependencies. `jq` is the one accepted exception, used by `permissions.sh` for JSON merging — no reasonable POSIX-only equivalent exists for that job. Don't introduce further runtime dependencies without the same bar (YAGNI).

### Testing

- Shell logic is tested with `bats-core`. Follow Red → Green: write the failing `.bats` test first, then implement.
- Tests exercise real filesystem operations (via `mktemp -d` fixtures) rather than mocking — the scripts' entire job is filesystem side effects, so mocking them would remove what's being verified.

### Git

- Conventional Commits in English.
- Branch naming: `feat/xxx`, `fix/xxx`, `docs/xxx`, `chore/xxx` — matching the Conventional Commits type used in the branch's commits.
