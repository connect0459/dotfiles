#!/usr/bin/env bash
# Cross-platform setup: symlinks shell rc files from home/common/ and the selected profile's home/<profile>/ into $HOME, then
# installs rustup and nvm. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/dry_run.sh"
source "$SCRIPT_DIR/libs/profile.sh"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

# Format: "<layer>:<layer-relative source path>:<$HOME-relative link path>"
# <layer> is "common" (always applied) or "profile" (the selected profile's
# directory under home/; a missing source removes the link instead).
DOTFILES="
common:.bashrc:.bashrc
common:.bash_profile:.bash_profile
common:.bash_aliases:.bash_aliases
common:.markdownlint.jsonc:.markdownlint.jsonc
common:dot_config/git/ignore:.config/git/ignore
common:dot_config/cabal/config:.config/cabal/config
profile:bashrc.sh:.config/dotfiles/profile.sh
"

PROFILE_STATE_FILE="$HOME/.config/dotfiles/profile"

PROFILE="$(profile_resolve "$REPO_DIR/home" "$PROFILE_STATE_FILE" "${DOTFILES_PROFILE:-}")" || exit 1

pln "$(term_bold 'Bootstrapping shell dotfiles') (profile: $PROFILE)"

for entry in $DOTFILES; do
  layer="${entry%%:*}"
  rest="${entry#*:}"
  src="${rest%%:*}"
  rel="${rest#*:}"
  case "$layer" in
    common) layer_dir="common" ;;
    profile) layer_dir="$PROFILE" ;;
  esac
  target="$REPO_DIR/home/$layer_dir/$src"
  link="$HOME/$rel"
  if [ "$layer" = "profile" ] && [ ! -f "$target" ]; then
    if [ -z "$SETUP_DRY_RUN" ] && [ -L "$link" ]; then
      rm -f "$link"
    fi
    continue
  fi
  if ! symlink_setup_reporting "$target" "$link"; then
    exit 1
  fi
done

echo
pln "$(term_bold 'Installing Rust toolchain (rustup)')"

if command -v rustup &> /dev/null; then
  pln "$(term_cyan 'rustup already installed, skipping')"
elif skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would install rustup from https://sh.rustup.rs')"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

NVM_VERSION="v0.40.5"
NVM_DIR="$HOME/.nvm"
NODE_VERSION="24.22"

echo
pln "$(term_bold 'Installing nvm')"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  pln "$(term_cyan 'nvm already installed, skipping')"
elif skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would install nvm' "$NVM_VERSION" 'from https://github.com/nvm-sh/nvm')"
else
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
fi

echo
pln "$(term_bold 'Installing Node via nvm')"

if skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would install Node' "$NODE_VERSION" 'via nvm and set it as the default')"
else
  . "$NVM_DIR/nvm.sh"
  if ! latest_node="$(nvm version-remote "$NODE_VERSION")"; then
    pln "$(term_red "Failed to resolve the latest Node $NODE_VERSION release from the nvm remote index")" >&2
    exit 1
  fi
  nvm install "$latest_node"
  nvm alias default "$latest_node"
fi
