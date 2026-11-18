# dotfiles

Personal dotfiles repository.

## Setup

Clone this repo anywhere, then run:

```sh
./scripts/setup.sh --profile <name>
```

## Profiles

A profile declares what a machine is used for, independently of its OS. `home/` is split into layers: `home/common/` is applied to every machine, and every other directory (`home/work/`, `home/personal/`) is a profile layer applied only when that profile is selected. Adding a directory makes a new profile selectable.

| Path | Effect |
| --- | --- |
| `home/<name>/Brewfile` | Installed by `setup-macos.sh` for this profile (skipped if absent) |
| `home/<name>/Aptfile.txt` | Installed by `setup-linux.sh` for this profile (skipped if absent) |
| `home/<name>/bashrc.sh` | Symlinked to `~/.config/dotfiles/profile.sh`, which `.bashrc` sources last (the link is removed if absent) |

The selection is recorded in `~/.config/dotfiles/profile`, so later runs can omit `--profile`. With neither a flag nor a recorded profile, setup fails instead of guessing. Passing `--profile` again switches the machine to another profile.

Current profiles: `work` (work macOS machine) and `personal` (personal WSL machine). Since profile and OS are independent axes, a personal Mac selects `personal`; note that `home/personal/` has no `Brewfile` yet, so packages such as `jq` (needed by `sync-agents`) must be installed by hand there.

## Conventions

See `AGENTS.md` for this repo's directory-naming, shell-scripting, and testing conventions.
