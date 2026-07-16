# sync

A port of the sync logic from `connect-labo/dev-settings/coding-agents/sync-cmd` (originally uv/Python) to shell, in order to minimize the dependency footprint.

## Current scope (skeleton stage)

`lib/*.sh` implements functions that map one-to-one to the original Python modules (`checksum.py` `symlink.py` `dirsync.py` `permissions.py` `term.py`), and `test/*.bats` verifies behavior equivalent to the original `tests/test_*.py`.

The following are intentionally out of scope for now:

- Writing to the real `$HOME` (`~/.claude` `~/.github` `~/.connect0459`)
- Wiring up the actual content from `connect-labo` (`AGENTS.md` `agent-docs/` `dot-claude/settings.json`)
- The orchestration behavior from the original `main.py` (e.g. the Change Detection Report)

These will be tackled separately, by agreement, once the fixture-only skeleton has proven stable.

## Module mapping

| lib | original module | notes |
| --- | --- | --- |
| `checksum.sh` | `checksum.py` | Ported for equality/inequality behavior only; exact hash values are not required to match |
| `symlink.sh` | `symlink.py` | |
| `dirsync.sh` | `dirsync.py` | |
| `permissions.sh` | `permissions.py` | Despite the name, performs a shallow merge of every top-level key from source, not just `permissions` (behavior asserted by `test_permissions.py`). The original repo's README describes this inaccurately. |
| `term.sh` | `term.py` | `TERM_FORCE_COLOR=1` overrides the tty check (for tests) |

## Dependencies

- bash (targets macOS's stock 3.2; no bash 4+ features such as associative arrays)
- `jq` (required for the JSON merge in `permissions.sh`)
- `shasum` (used by `checksum.sh`; ships with macOS)
- `bats-core` (test runner only; `brew install bats-core`)

## Running tests

```sh
bats sync/test/*.bats
shellcheck sync/lib/*.sh
```
