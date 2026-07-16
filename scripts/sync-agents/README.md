# sync-agents

A shell tool that distributes the agent-config content in `../../home/dot_agents/` and `../../home/dot_claude/` into the real `$HOME`, with no runtime dependency beyond what macOS ships plus `jq`.

## Scope

`libs/*.sh` implements the individual filesystem primitives this needs — content checksums, symlink setup, directory sync, and a JSON permissions merge — each covered by `tests/*.bats`.

`sync-agents.sh` is the orchestration entry point. It reads from `../../home/` (this repo's canonical copy of `dot_agents/AGENTS.md`, `dot_agents/agent-docs/**`, and `dot_claude/settings.json` — see `../../home/dot_agents/AGENTS.md`) and writes to the real `$HOME`:

- Copies `AGENTS.md` into `~/.agents/AGENTS.md` and syncs `agent-docs/` into `~/.agents/agent-docs/`
- Merges `dot_claude/settings.json`'s top-level keys into `~/.claude/settings.json` (skipped if the source file doesn't exist)
- Sets up `~/.claude/CLAUDE.md` and `~/.github/copilot-instructions.md` as symlinks to the central `AGENTS.md`
- Prints a Change Detection Report of what changed

Run it with:

```sh
scripts/sync-agents/sync-agents.sh
```

`SYNC_SOURCE_DIR` overrides the source directory (used by `tests/sync-agents.bats` so tests never touch the real `$HOME` or read from the real source).

One quirk worth knowing: the report's symlink rows are driven by whether the symlink exists, not by whether it actually changed — so they always show as changed once the symlinks are set up, even on a no-op run.

## Modules

| lib | responsibility |
| --- | --- |
| `checksum.sh` | Computes a content digest for a file or directory tree. The digest is an internal implementation detail — only equality/inequality between two digests is meaningful, never the literal value. |
| `symlink.sh` | Sets up `link` as a symlink to `target`, refusing to replace an existing real directory. Backs up a pre-existing real file to `<link>.bak` before replacing it with a symlink, since this runs against the real `$HOME`. |
| `dirsync.sh` | Syncs a directory tree from `src` to `dst`: copies everything in `src`, and removes anything in `dst` that `src` no longer has (including directories left empty as a result), so `dst` always ends up mirroring `src` exactly. |
| `permissions.sh` | Merges every top-level key from a source JSON file into a target JSON file (source wins on conflicts) — despite the name, not limited to a `permissions` key. Nested objects are merged recursively rather than replaced outright, and `permissions.allow`/`deny`/`ask` are additionally unioned (deduped, sorted) — see the comment in `permissions.sh` for the tradeoff this accepts. |
| `term.sh` | Wraps text in ANSI color codes when stdout is a tty (or `TERM_FORCE_COLOR=1` is set, for tests); passes text through unchanged otherwise. |
| `sync-agents.sh` | Orchestration; see Scope above. |

## Dependencies

- bash (targets macOS's stock 3.2; no bash 4+ features such as associative arrays)
- `jq` (required for the JSON merge in `permissions.sh`)
- `shasum` (used by `checksum.sh`; ships with macOS)
- `bats-core` (test runner only; `brew install bats-core`)

## Running tests

```sh
bats scripts/sync-agents/tests/*.bats
shellcheck scripts/sync-agents/libs/*.sh scripts/sync-agents/sync-agents.sh
```
