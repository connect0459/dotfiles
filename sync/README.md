# sync

A port of the sync logic from `connect-labo/dev-settings/coding-agents/sync-cmd` (originally uv/Python) to shell, in order to minimize the dependency footprint.

## Scope

`lib/*.sh` implements functions that map one-to-one to the original Python modules (`checksum.py` `symlink.py` `dirsync.py` `permissions.py` `term.py`), and `test/*.bats` verifies behavior equivalent to the original `tests/test_*.py`.

`sync.sh` is the orchestration entry point, ported from the original `main.py`. It reads from `../coding-agents/` (this repo's canonical copy of `AGENTS.md`, `agent-docs/**`, and `dot-claude/settings.json` — see `../coding-agents/README.md`) and writes to the real `$HOME`:

- Copies `AGENTS.md` and syncs `agent-docs/` into `~/.connect0459/coding-agents/`
- Merges `dot-claude/settings.json`'s top-level keys into `~/.claude/settings.json` (skipped if the source file doesn't exist)
- Sets up `~/.claude/CLAUDE.md` and `~/.github/copilot-instructions.md` as symlinks to the central `AGENTS.md`
- Prints a Change Detection Report, same format as the original `main.py`

Run it with:

```sh
sync/sync.sh
```

`SYNC_SOURCE_DIR` overrides the source directory (used by `test/sync.bats` so tests never touch the real `$HOME` or read from the real source).

One faithfully-ported quirk from the original `main.py`: the report's symlink rows are driven by `is_symlink()`, not by whether the symlink actually changed — so they always show as changed once the symlinks exist, even on a no-op run.

## Module mapping

| lib | original module | notes |
| --- | --- | --- |
| `checksum.sh` | `checksum.py` | Ported for equality/inequality behavior only; exact hash values are not required to match |
| `symlink.sh` | `symlink.py` | |
| `dirsync.sh` | `dirsync.py` | |
| `permissions.sh` | `permissions.py` | Despite the name, performs a shallow merge of every top-level key from source, not just `permissions` (behavior asserted by `test_permissions.py`). The original repo's README describes this inaccurately. |
| `term.sh` | `term.py` | `TERM_FORCE_COLOR=1` overrides the tty check (for tests) |
| `sync.sh` | `main.py` | Orchestration; see Scope above |

## Dependencies

- bash (targets macOS's stock 3.2; no bash 4+ features such as associative arrays)
- `jq` (required for the JSON merge in `permissions.sh`)
- `shasum` (used by `checksum.sh`; ships with macOS)
- `bats-core` (test runner only; `brew install bats-core`)

## Running tests

```sh
bats sync/test/*.bats
shellcheck sync/lib/*.sh sync/sync.sh
```
