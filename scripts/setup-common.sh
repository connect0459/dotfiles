#!/usr/bin/env bash
# Cross-platform setup: symlinks shell rc files from home/ into $HOME,
# installs rustup and nvm, then delegates to sync-agents/sync-agents.sh
# for coding-agent config distribution. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/dry_run.sh"
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

if command -v rustup &> /dev/null; then
  pln "$(term_cyan 'rustup already installed, skipping')"
elif skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would install rustup from https://sh.rustup.rs')"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

NVM_VERSION="v0.40.5"
NVM_DIR="$HOME/.nvm"
NODE_VERSION="24.15.0"

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
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
fi

echo
exec "$SCRIPT_DIR/sync-agents/sync-agents.sh"
