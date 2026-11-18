#!/usr/bin/env bash
# macOS-specific setup: installs dependencies from the selected profile's Brewfile, installs Ruby via
# rbenv, symlinks VS Code user settings, and configures bash. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/dry_run.sh"
source "$SCRIPT_DIR/libs/profile.sh"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

PROFILE="$(profile_resolve "$REPO_DIR/home" "$HOME/.config/dotfiles/profile" "${DOTFILES_PROFILE:-}")" || exit 1
BREWFILE="$REPO_DIR/home/$PROFILE/Brewfile"

pln "$(term_bold 'Installing macOS dependencies from Brewfile')"

if [ ! -f "$BREWFILE" ]; then
  pln "$(term_cyan "No Brewfile for profile $PROFILE, skipping")"
elif skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would install from' "$BREWFILE")"
else
  if ! command -v brew &> /dev/null; then
    pln "$(term_red 'brew not found. Please install Homebrew from https://brew.sh')" >&2
    exit 1
  fi
  brew bundle install --file="$BREWFILE"
fi

RUBY_VERSION="3.4.5"

echo
pln "$(term_bold 'Installing Ruby via rbenv')"

if skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would install Ruby' "$RUBY_VERSION" 'via rbenv and set it as the global default')"
else
  eval "$(rbenv init - bash)"
  rbenv install --skip-existing "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
fi

echo
pln "$(term_bold 'Symlinking VS Code user settings')"

VSCODE_SETTINGS_LINK="$HOME/Library/Application Support/Code/User/settings.json"
if ! symlink_setup_reporting "$REPO_DIR/home/common/dot_config/Code/User/settings.json" "$VSCODE_SETTINGS_LINK"; then
  exit 1
fi

if command -v brew &> /dev/null; then
  HOMEBREW_BASH="$(brew --prefix)/bin/bash"
  if [ -x "$HOMEBREW_BASH" ] && [ "$SHELL" != "$HOMEBREW_BASH" ]; then
    pln
    pln "$(term_bold 'Homebrew bash installed.')"
    pln "$(term_cyan 'To set it as your login shell, run:')"
    pln "  echo $HOMEBREW_BASH | sudo tee -a /etc/shells"
    pln "  chsh -s $HOMEBREW_BASH"
  fi
fi
