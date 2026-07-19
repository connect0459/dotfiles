# dotfiles

Personal dotfiles for POSIX: real shell rc files under their real names, plus a
shell tool that distributes coding-agent instructions into `$HOME`. Everything
that ends up under `$HOME` lives in `home/`; every automation script lives in
`scripts/`.

## Setup

Clone this repo anywhere, then run:

```sh
./scripts/setup.sh
```

This runs `scripts/setup-common.sh` (which symlinks `home/.bashrc`, `home/.bash_profile`,
`home/.bash_aliases`, `home/dot_config/git/ignore`, and `home/dot_config/mise/config.toml`
into `$HOME` as `.bashrc`, `.bash_profile`, `.bash_aliases`, `.config/git/ignore`, and
`.config/mise/config.toml`, backing up any pre-existing real file to `<file>.bak` first;
installs the cross-platform toolchains rustup and mise via their respective install
scripts, then runs `mise install` against the now-global `~/.config/mise/config.toml`
(mise's global tool-version config, replacing per-language version managers like nvm or
rbenv); and finally delegates to `scripts/sync-agents/sync-agents.sh` for the
coding-agent config distribution described below), and then runs a platform-specific
setup script if applicable: `scripts/setup-macos.sh` on macOS installs dependencies
from `home/Brewfile` via Homebrew, and both it and `scripts/setup-linux.sh` on Linux
symlink `home/dot_config/Code/User/settings.json` into the platform's VS Code user
settings path (`~/Library/Application Support/Code/User/settings.json` on macOS,
`~/.config/Code/User/settings.json` on Linux). Safe to re-run.

## Usage

### Shell dotfiles

Once symlinked, a new shell picks these up automatically — nothing else to run.

### Syncing coding-agent config

`setup.sh` runs this automatically, but it can also be run standalone to pick up
`home/dot_agents/` or `home/dot_claude/` changes without re-symlinking the shell dotfiles:

```sh
scripts/sync-agents/sync-agents.sh
```

Copies `home/dot_agents/AGENTS.md` to `~/.agents/AGENTS.md` and syncs
`home/dot_agents/agent-docs/` to `~/.agents/agent-docs/`, symlinks `~/.claude/CLAUDE.md` and
`~/.github/copilot-instructions.md` to it, and merges `home/dot_claude/settings.json`
into `~/.claude/settings.json`. Safe to re-run — see `scripts/sync-agents/README.md`
for exactly what it touches, its one dependency beyond stock macOS (`jq`), and how to
run its tests.

`home/dot_agents/AGENTS.md` and `home/dot_agents/agent-docs/**` are kept in Japanese
intentionally: they are the user's personal instruction content for coding agents,
not project documentation, so the English-only convention below does not apply to them.

## Development

After setup, develop this repository with:

```sh
just lint    # shellcheck all shell scripts
just test    # run all bats tests
just verify  # lint + test (CI gate)
```

See `justfile` for recipes. This is development tooling for the repository itself;
setup (`scripts/setup.sh`) is distribution infrastructure for users, and requires no
development dependencies.

## Conventions

See `AGENTS.md` for this repo's directory-naming, shell-scripting, and testing
conventions.
