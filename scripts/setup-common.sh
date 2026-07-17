#!/usr/bin/env bash
# Cross-platform setup: symlinks shell rc files from home/ into $HOME,
# installs rustup, then delegates to sync-agents/sync-agents.sh for
# coding-agent config distribution. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/sync-agents/libs/symlink.sh"
source "$SCRIPT_DIR/sync-agents/libs/term.sh"

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
  mkdir -p "$(dirname "$link")"
  if ! symlink_setup "$target" "$link"; then
    pln "$(term_red "failed to symlink $rel")" >&2
    exit 1
  fi
  echo "  $link -> $target"
done

echo
pln "$(term_bold 'Installing Rust toolchain (rustup)')"

if [ -n "$SETUP_DRY_RUN" ]; then
  pln "$(term_cyan '[DRY RUN] Would install rustup from https://sh.rustup.rs')"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

echo
exec "$SCRIPT_DIR/sync-agents/sync-agents.sh"
