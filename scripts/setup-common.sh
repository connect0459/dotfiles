#!/usr/bin/env bash
# Cross-platform setup: symlinks shell rc files from home/ into $HOME,
# installs rustup, then delegates to sync-agents/sync-agents.sh for
# coding-agent config distribution. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

# Format: "<home/-relative source path>:<$HOME-relative link path>"
DOTFILES="
.bashrc:.bashrc
.bash_profile:.bash_profile
.bash_aliases:.bash_aliases
dot_config/git/ignore:.config/git/ignore
"

pln "$(term_bold 'Bootstrapping shell dotfiles')"

for pair in $DOTFILES; do
  src="${pair%%:*}"
  rel="${pair#*:}"
  target="$REPO_DIR/home/$src"
  link="$HOME/$rel"
  if ! symlink_setup_reporting "$target" "$link"; then
    exit 1
  fi
done

echo
pln "$(term_bold 'Installing Rust toolchain (rustup)')"

# SETUP_SKIP_NETWORK_INSTALLS is a test-only escape hatch: unlike
# SETUP_DRY_RUN, it skips only these network-fetching installs, letting
# tests exercise real symlinking without also hitting the network.
if [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]; then
  pln "$(term_cyan '[DRY RUN] Would install rustup from https://sh.rustup.rs')"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

MISE_BIN="$HOME/.local/bin/mise"

echo
pln "$(term_bold 'Installing mise')"

if [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]; then
  pln "$(term_cyan '[DRY RUN] Would install mise from https://mise.run')"
else
  curl https://mise.run | sh
fi

echo
pln "$(term_bold 'Installing mise-managed tools')"

if [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]; then
  pln "$(term_cyan '[DRY RUN] Would install mise tools from' "$REPO_DIR/.mise.toml")"
else
  "$MISE_BIN" install -C "$REPO_DIR"
fi

echo
exec "$SCRIPT_DIR/sync-agents/sync-agents.sh"
