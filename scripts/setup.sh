#!/usr/bin/env bash
# Bootstraps a fresh clone of this repo: symlinks the real shell rc files
# from home/ into $HOME, then delegates to sync-agents/sync-agents.sh for
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
exec "$SCRIPT_DIR/sync-agents/sync-agents.sh"
