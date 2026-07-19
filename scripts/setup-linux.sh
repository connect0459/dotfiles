#!/usr/bin/env bash
# Linux-specific setup: installs Ruby via rbenv and symlinks VS Code user
# settings. Assumes an apt-based (Debian/Ubuntu) distribution. Safe to
# re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/dry_run.sh"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

RBENV_ROOT="$HOME/.rbenv"
RUBY_VERSION="3.4.5"
# Suggested build environment for Ubuntu/Debian/Mint, per
# https://github.com/rbenv/ruby-build/wiki. If a package like libgdbm6 isn't
# available on your distro version, try an older alias (e.g. libgdbm5).
RUBY_BUILD_DEPS=(
  build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev
  libgmp-dev rustc patch libreadline6-dev libncurses5-dev libgdbm6
  libgdbm-dev libdb-dev
)

pln "$(term_bold 'Installing Ruby build dependencies')"

if skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would apt-get install Ruby build dependencies:' "${RUBY_BUILD_DEPS[*]}")"
else
  sudo apt-get update
  sudo apt-get install -y "${RUBY_BUILD_DEPS[@]}"
fi

echo
pln "$(term_bold 'Installing rbenv')"

if skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would clone rbenv and ruby-build into' "$RBENV_ROOT")"
else
  if [ ! -x "$RBENV_ROOT/bin/rbenv" ]; then
    git clone https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
  fi
  if [ ! -x "$RBENV_ROOT/plugins/ruby-build/bin/ruby-build" ]; then
    git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT/plugins/ruby-build"
  fi
fi

echo
pln "$(term_bold 'Installing Ruby via rbenv')"

if skip_network_install; then
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
