# dotfiles

Personal dotfiles repository.

## Setup

Clone this repo anywhere, then run:

```sh
./scripts/setup.sh
```

## Development

After setup, develop this repository with:

```sh
just lint    # shellcheck all shell scripts
just test    # run all bats tests
just verify  # lint + test (CI gate)
```

See `justfile` for recipes.

## Conventions

See `AGENTS.md` for this repo's directory-naming, shell-scripting, and testing conventions.
