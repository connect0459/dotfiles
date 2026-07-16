# AGENTS.md / CLAUDE.md

## Primary Directive

- Think in English. For user interaction language, follow the setting in the user's global `AGENTS.md`, `CLAUDE.md`, or `CLAUDE.local.md`.

## Language Convention

This project is intended for public release. All of the following must be written in **English**:

- Commit messages
- Documentation (including `AGENTS.md`, `README.md`, and any `sync/README.md`-style subdirectory docs)

## Project Overview

This is a personal dotfiles repository. It manages real shell rc files (`.bashrc`, `.bash_profile`, `.bash_aliases`, `.config/git/ignore`, etc.) directly under real file names — no GNU Stow or chezmoi. There is currently no install/bootstrap script; see the root `README.md` for the actual file inventory.

`sync/` hosts a shell sync tool, and `coding-agents/` is the canonical source content it distributes — `AGENTS.md`, `agent-docs/**`, and `dot-claude/settings.json`. `sync/sync.sh` writes this into the real `$HOME` (`~/.connect0459/coding-agents/`, symlinked from `~/.claude/CLAUDE.md` and `~/.github/copilot-instructions.md`, plus a permissions merge into `~/.claude/settings.json`). See `sync/README.md` and `coding-agents/README.md` for details.

## Conventions

### Directory naming

- A directory or file gets the `dot-foo` prefix **only** when it is symlinked, physically copied 1:1, or merged onto a real hidden path (e.g. `~/.foo`) — as `coding-agents/dot-claude/settings.json` is, via a merge into `~/.claude/settings.json`.
- Content that is not itself a hidden-path target (tooling, documentation, source scripts) uses a plain name — do not prefix it with `dot-`.

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
