# Templates

Reference material that isn't safe to manage as a symlinked dotfile —
values that are machine-specific, get rewritten at runtime, or otherwise
shouldn't be tracked as a live file under `home/`. Each subdirectory below
covers one tool; copy the values you need by hand instead of symlinking.

## colima

Reference material for this machine's Colima setup. Colima and Docker
themselves are installed via `home/Brewfile` (see `scripts/setup-macos.sh`).

### Why `colima.yaml` isn't a symlinked dotfile

`~/.colima/default/colima.yaml` is not tracked directly, for two reasons:

- **Values are machine-specific.** `disk`, `cpu`, and `memory` should be
  sized against each host's actual free space and resources, not fixed to
  one machine's numbers.
- **Colima rewrites the file at runtime.** It fills in defaults and can
  drop or reorder comments on write. Symlinking it into this repo would
  mean colima's own runtime behavior dirties a tracked file.

`colima.yaml.example` is a plain reference file instead: copy the values
you want into `~/.colima/default/colima.yaml` by hand (or via
`colima start --edit`), adjusting for the current host.

### Cleanup

Colima's raw disk image is a sparse file that grows as containers/images
are created but does not shrink on its own — deleting files inside the VM
does not release space back to the host filesystem. Run:

```sh
scripts/colima-cleanup.sh
```

periodically (see `scripts/colima-cleanup.sh --help`) to reclaim it via
`docker system prune` + `fstrim`, rather than waiting until the host disk
is nearly full.
