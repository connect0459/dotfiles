# Templates

Reference material that isn't safe to manage as a symlinked dotfile: values that are machine-specific, get rewritten at runtime, or otherwise shouldn't be tracked as a live file under `home/`. Each subdirectory below covers one tool. Copy the values you need by hand instead of symlinking.

## colima

Reference material for this machine's Colima setup. Colima and Docker are installed via `home/work/Brewfile` (see `scripts/setup-macos.sh`).

### Why `colima.yaml` isn't a symlinked dotfile

`~/.colima/default/colima.yaml` is not tracked directly, for two reasons:

- **Values are machine-specific.** `disk`, `cpu`, and `memory` should be sized against each host's actual free space and resources, not fixed to one machine's numbers.
- **Colima rewrites the file at runtime.** It fills in defaults and can drop or reorder comments on write. Symlinking it into this repo would let colima's own runtime behavior dirty a tracked file.

`colima.example.yaml` is a plain reference file instead: copy the values you want into `~/.colima/default/colima.yaml` by hand (or via `colima start --edit`), adjusting for the current host.

`~/.colima/default/colima.yaml` itself is generated from `~/.colima/_templates/default.yaml` when the `default` profile is created, so edits made directly to `colima.yaml` last only until the VM is recreated. To make a change persist across profile recreation, edit `~/.colima/_templates/default.yaml` instead.

### Cleanup

Colima's raw disk image is a sparse file that grows as containers and images are created but does not shrink on its own: deleting files inside the VM does not release space to the host filesystem. Run:

```sh
scripts/colima/colima-cleanup.sh
```

periodically (see `scripts/colima/colima-cleanup.sh --help`) to reclaim the space via `docker system prune` and `fstrim`, rather than waiting until the host disk is nearly full.

## docker

Reference material for this machine's Docker CLI configuration. `docker` and `docker-compose` are installed via `home/work/Brewfile`.

### Why `config.json` isn't a symlinked dotfile

`~/.docker/config.json` is not tracked directly, for two reasons:

- **`cliPluginsExtraDirs` is machine-specific.** The path is Homebrew's `lib/docker/cli-plugins` directory, which differs by CPU architecture: `/opt/homebrew` on Apple Silicon, `/usr/local` on Intel. Run `brew --prefix` on the target host and adjust the path before copying.
- **`auths` accumulates machine-specific, sensitive state.** `docker login` writes registry credentials into this file. With no `credsStore` / `credHelpers` configured, those credentials are stored as plain base64 (not encrypted) directly in `config.json`. Before running `docker login`, consider installing a credential helper (e.g., `docker-credential-helper` for macOS Keychain via `osxkeychain`) and setting `credsStore` accordingly. Otherwise, treat any `auths` entries in your live `config.json` as sensitive and never copy them back into this template.

`config.json` is a plain reference file instead: copy the values you want into `~/.docker/config.json` by hand, adjusting `cliPluginsExtraDirs` for the current host's Homebrew prefix.

### Context prerequisite

`currentContext: "colima"` assumes the `colima` context already exists, which happens only after you run `colima start` at least once. Setting this before starting Colima makes every `docker` command fail with a `context not found` error.
