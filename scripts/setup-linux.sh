#!/usr/bin/env bash
# Linux-specific setup: installs Ruby via rbenv and symlinks VS Code user
# settings. Assumes an apt-based (Debian/Ubuntu) distribution. Safe to
# re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/apt.sh"
source "$SCRIPT_DIR/libs/dry_run.sh"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

RBENV_ROOT="$HOME/.rbenv"
RUBY_VERSION="3.4.5"
# Overridable so tests can point at a scratch file instead of the real
# home/Aptfile.txt
APTFILE="${APTFILE:-$REPO_DIR/home/Aptfile.txt}"

if ! APT_PACKAGES_OUTPUT="$(apt_packages_from_file "$APTFILE")"; then
  pln "$(term_red "Failed to read apt package list from $APTFILE")" >&2
  exit 1
fi

APT_DEPS=()
while IFS= read -r pkg; do
  [ -n "$pkg" ] && APT_DEPS+=("$pkg")
done <<< "$APT_PACKAGES_OUTPUT"

if [ "${#APT_DEPS[@]}" -eq 0 ]; then
  pln "$(term_red "No apt packages found in $APTFILE")" >&2
  exit 1
fi

pln "$(term_bold 'Installing apt dependencies')"

if skip_network_install; then
  pln "$(term_cyan '[DRY RUN] Would apt-get install:' "${APT_DEPS[*]}")"
else
  sudo apt-get update
  sudo apt-get install -y "${APT_DEPS[@]}"
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
