#!/usr/bin/env bash
# macOS-specific setup: installs dependencies from Brewfile, symlinks VS Code
# user settings, and configures bash. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

if ! command -v brew &> /dev/null; then
  pln "$(term_red 'brew not found. Please install Homebrew from https://brew.sh')" >&2
  exit 1
fi

if [ -f "$REPO_DIR/home/Brewfile" ]; then
  pln "$(term_bold 'Installing macOS dependencies from Brewfile')"

  # SETUP_SKIP_NETWORK_INSTALLS is a test-only escape hatch: unlike
  # SETUP_DRY_RUN, it skips only this install, letting tests exercise real
  # symlinking without also hitting the network.
  if [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]; then
    pln "$(term_cyan '[DRY RUN] Would install from' "$REPO_DIR/home/Brewfile")"
  else
    brew bundle install --file="$REPO_DIR/home/Brewfile"
  fi
else
  pln "$(term_red 'Brewfile not found at' "$REPO_DIR/home/Brewfile")" >&2
  exit 1
fi

echo
pln "$(term_bold 'Symlinking VS Code user settings')"

VSCODE_SETTINGS_LINK="$HOME/Library/Application Support/Code/User/settings.json"
if ! symlink_setup_reporting "$REPO_DIR/home/dot_config/Code/User/settings.json" "$VSCODE_SETTINGS_LINK"; then
  exit 1
fi

HOMEBREW_BASH="$(brew --prefix)/bin/bash"
if [ -x "$HOMEBREW_BASH" ] && [ "$SHELL" != "$HOMEBREW_BASH" ]; then
  pln
  pln "$(term_bold 'Homebrew bash installed.')"
  pln "$(term_cyan 'To set it as your login shell, run:')"
  pln "  echo $HOMEBREW_BASH | sudo tee -a /etc/shells"
  pln "  chsh -s $HOMEBREW_BASH"
fi
