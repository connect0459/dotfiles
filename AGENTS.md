# AGENTS.md / CLAUDE.md

## Primary Directive

- Think in English. For user interaction language, follow the setting in the user's global `AGENTS.md`, `CLAUDE.md`, or `CLAUDE.local.md`.

## Language Convention

This project is intended for public release. All of the following must be written in **English**:

- Commit messages
- Documentation (including `AGENTS.md`, `README.md`, and any `scripts/sync-agents/README.md`-style subdirectory docs)

Exception: `home/dot_agents/AGENTS.md` and `home/dot_agents/agent-docs/**` are not project documentation — they are the user's personal instruction content for coding agents, distributed as-is by `scripts/sync-agents/sync-agents.sh`, and are kept in Japanese intentionally.

## Project Overview

This is a personal dotfiles repository. `home/` is the canonical source of everything that ends up under `$HOME`, mixing shell rc files under their real dotted names with `dot_`-prefixed directories for content that lands one level deeper. No GNU Stow or chezmoi. See the root `README.md` for the actual file inventory and the Directory naming convention below for the naming rule.

`scripts/` holds every automation script this repo ships, each paired with its own tests. `scripts/setup.sh` is the entry point — it symlinks the plain dotfiles from `home/` into `$HOME`, then delegates to `scripts/sync-agents/sync-agents.sh` for the coding-agent config distribution. See `scripts/sync-agents/README.md` for what that covers.

## Development Philosophy

### Red/Green TDD (Detroit school)

- Shell logic is tested with `bats-core`.
- Red → Green → Refactor cycle strictly followed: write the failing test first, then implement.
- Use real filesystem operations (via `mktemp -d` fixtures) rather than mocks — the scripts' entire job is filesystem side effects, so mocking them would remove what's being verified.
- Discuss coverage targets with the user before starting implementation.

### Evergreen Tests

- Test names describe WHAT behavior is being verified, not HOW.
- Error messages describe a concrete operation or state, not the name of the function/script that produced them; renaming that function must never obligate an error-string edit.
- Test code serves as living documentation of the system's behavior.

### Code Comments

- Do NOT write code comments unless explicitly permitted by the user.
- Let the code speak for itself; let tests document the behavior.
- Code = How, Tests = What, Commit messages = Why.

## Conventions

### Directory naming

- A directory gets the `dot_foo` prefix (underscore, not a literal leading dot) when its contents are symlinked, physically copied, or merged onto a real path one level under `$HOME` — e.g. `home/dot_config/` → `~/.config/`.
- A file that is itself the direct symlink target keeps its real dotted name instead (e.g. `home/.bashrc`, not `home/dot_bashrc`).
- Content that is not itself a hidden-path target (tooling, documentation, source scripts) uses a plain name — do not prefix it with `dot_`.

### Shell scripts

- Target bash 3.2 compatibility (macOS's stock `/bin/bash`) — no bash 4+ features (associative arrays, `mapfile`, etc.).
- Every script under `lib/` must pass `shellcheck` with no warnings.
- Prefer POSIX/portable tools already present on macOS (`find`, `shasum`, `awk`) over adding new runtime dependencies. `jq` is the one accepted exception, used by `permissions.sh` for JSON merging — no reasonable POSIX-only equivalent exists for that job. Don't introduce further runtime dependencies without the same bar (YAGNI).

## Git Conventions

- Conventional Commits in English.
- Branch naming: `feat/xxx`, `fix/xxx`, `docs/xxx`, `chore/xxx` — matching the Conventional Commits type used in the branch's commits.
