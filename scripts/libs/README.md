# scripts/libs

Shared shell helpers with no ties to a single subsystem — used by the top-level bootstrap scripts (`scripts/setup.sh`, `setup-common.sh`, `setup-macos.sh`, `setup-linux.sh`) and by `scripts/sync-agents/sync-agents.sh` alike. Anything private to one subsystem belongs in that subsystem's own `libs/` instead (see `scripts/sync-agents/libs/` and its README).

## Modules

| lib | responsibility |
| --- | --- |
| `apt.sh` | Provides `apt_packages_from_file`, which reads a plain-text apt package list (see `home/Aptfile.txt`) and prints one package per line, skipping blank lines and `#`-prefixed comments. Keeps apt package declarations data rather than logic, mirroring how `home/Brewfile` keeps brew's packages declarative. |
| `dry_run.sh` | Provides `skip_network_install`, the shared gate every network-fetching install step (rustup, nvm, Homebrew/apt, rbenv, ...) checks: true when `SETUP_DRY_RUN` is set, or when the test-only `SETUP_SKIP_NETWORK_INSTALLS` escape hatch is set. |
| `symlink.sh` | Sets up `link` as a symlink to `target`, refusing to replace an existing real directory. Backs up a pre-existing real file to `<link>.bak` before replacing it with a symlink, since this runs against the real `$HOME`. Also provides `symlink_setup_reporting`, the reporting wrapper every bootstrap script uses: it creates `link`'s parent directory, honors `SETUP_DRY_RUN` by printing what it would do instead of touching the filesystem, and depends on `term.sh`'s `pln`/`term_cyan`/`term_red` for that output — every current caller already sources both. |
| `term.sh` | Wraps text in ANSI color codes when stdout is a tty (or `TERM_FORCE_COLOR=1` is set, for tests); passes text through unchanged otherwise. |

## Consumers

- `scripts/setup.sh`, `scripts/setup-common.sh`, `scripts/setup-macos.sh`, `scripts/setup-linux.sh` (bootstrap entry points)
- `scripts/sync-agents/sync-agents.sh` (coding-agent config sync tool)

## Dependencies

- bash (targets macOS's stock 3.2; no bash 4+ features such as associative arrays)
- `bats-core` (test runner only; `brew install bats-core`)

## Running tests

```sh
bats scripts/tests/apt.bats scripts/tests/dry_run.bats scripts/tests/symlink.bats scripts/tests/term.bats
shellcheck scripts/libs/*.sh
```
