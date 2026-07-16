# AGENTS.md / CLAUDE.md

## Primary Directive

- Think in English. For user interaction language, follow the setting in the user's global `AGENTS.md`, `CLAUDE.md`, or `CLAUDE.local.md`.

## Language Convention

This project is intended for public release. All of the following must be written in **English**:

- Commit messages
- Documentation (including `AGENTS.md`, `README.md`, and any `sync/README.md`-style subdirectory docs)

## Project Overview

This is a personal dotfiles repository. It manages real shell rc files (`.bashrc`, `.bash_profile`, `.bash_aliases`, `.config/git/ignore`, etc.) directly under real file names — no GNU Stow or chezmoi. There is currently no install/bootstrap script; see the root `README.md` for the actual file inventory.

`sync/` hosts a shell port of the sync tool from `connect-labo/dev-settings/coding-agents/sync-cmd` (originally uv/Python), aimed at eventually consolidating coding-agent config distribution (Claude/Copilot instructions, `settings.json` permissions, skills) into this repo. See `sync/README.md` for its current scope — it is intentionally a skeleton (fixture-only tests, no real `$HOME` or `connect-labo` wiring yet).

## Conventions

### Directory naming

- A directory or file gets the `dot-foo` prefix **only** when it is symlinked or physically copied 1:1 onto a real hidden path (e.g. `~/.foo`). This mirrors the existing convention in `connect-labo/dev-settings/coding-agents/dot-claude/`.
- Content that is not itself a hidden-path target (tooling, documentation, source scripts) uses a plain name — do not prefix it with `dot-`.

### Shell scripts

- Target bash 3.2 compatibility (macOS's stock `/bin/bash`) — no bash 4+ features (associative arrays, `mapfile`, etc.).
- Every script under `lib/` must pass `shellcheck` with no warnings.
- Prefer POSIX/portable tools already present on macOS (`find`, `shasum`, `awk`) over adding new runtime dependencies. Add a new dependency (e.g. `jq`) only when the task genuinely requires it (YAGNI).

### Testing

- Shell logic is tested with `bats-core`. Follow Red → Green: write the failing `.bats` test first, then implement.
- Tests exercise real filesystem operations (via `mktemp -d` fixtures) rather than mocking — the scripts' entire job is filesystem side effects, so mocking them would remove what's being verified.

### Git

- Conventional Commits in English.
- Branch naming: `feature/xxx`, `fix/xxx`, `docs/xxx`.
