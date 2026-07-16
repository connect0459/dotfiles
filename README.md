# dotfiles

Personal dotfiles for POSIX: real shell rc files under their real names, plus a
shell tool that distributes coding-agent instructions into `$HOME`.

## Setup

There is no install/bootstrap script yet — symlink what you want by hand:

<!-- TODO: once a setup script exists, replace this with: clone this repo directly
     under $HOME, then run the setup script — no manual symlinking. -->

```sh
ln -sf "$(pwd)/.bashrc" ~/.bashrc
ln -sf "$(pwd)/.bash_profile" ~/.bash_profile
ln -sf "$(pwd)/.bash_aliases" ~/.bash_aliases
mkdir -p ~/.config/git
ln -sf "$(pwd)/.config/git/ignore" ~/.config/git/ignore
```

## Usage

### Shell dotfiles

Once symlinked, a new shell picks these up automatically — nothing else to run.

### Syncing coding-agent config

```sh
sync/sync.sh
```

Copies `coding-agents/AGENTS.md` and `agent-docs/` to `~/.connect0459/coding-agents/`,
symlinks `~/.claude/CLAUDE.md` and `~/.github/copilot-instructions.md` to it, and merges
`coding-agents/dot-claude/settings.json` into `~/.claude/settings.json`. Safe to re-run —
see `sync/README.md` for exactly what it touches, its one dependency beyond stock macOS
(`jq`), and how to run its tests.

## Conventions

See `AGENTS.md` for this repo's directory-naming, shell-scripting, and testing
conventions.
