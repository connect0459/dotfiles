#!/usr/bin/env bash
# Linux-specific setup: installs Ruby via rbenv and symlinks VS Code user
# settings. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

RBENV_ROOT="$HOME/.rbenv"
RUBY_VERSION="3.4.5"

pln "$(term_bold 'Installing rbenv')"

if [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]; then
  pln "$(term_cyan '[DRY RUN] Would clone rbenv and ruby-build into' "$RBENV_ROOT")"
else
  if [ ! -d "$RBENV_ROOT" ]; then
    git clone https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
  fi
  if [ ! -d "$RBENV_ROOT/plugins/ruby-build" ]; then
    git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT/plugins/ruby-build"
  fi
fi

echo
pln "$(term_bold 'Installing Ruby via rbenv')"

if [ -n "$SETUP_DRY_RUN" ] || [ -n "$SETUP_SKIP_NETWORK_INSTALLS" ]; then
  pln "$(term_cyan '[DRY RUN] Would install Ruby' "$RUBY_VERSION" 'via rbenv and set it as the global default')"
else
  export PATH="$RBENV_ROOT/bin:$PATH"
  eval "$(rbenv init - bash)"
  rbenv install --skip-existing "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
fi

echo
pln "$(term_bold 'Symlinking VS Code user settings')"

VSCODE_SETTINGS_LINK="$HOME/.config/Code/User/settings.json"
if ! symlink_setup_reporting "$REPO_DIR/home/dot_config/Code/User/settings.json" "$VSCODE_SETTINGS_LINK"; then
  exit 1
fi
