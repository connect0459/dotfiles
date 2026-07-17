#!/usr/bin/env bash
# Linux-specific setup: symlinks VS Code user settings. Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/libs/symlink.sh"
source "$SCRIPT_DIR/libs/term.sh"

pln "$(term_bold 'Symlinking VS Code user settings')"

VSCODE_SETTINGS_LINK="$HOME/.config/Code/User/settings.json"
if ! symlink_setup_reporting "$REPO_DIR/home/dot_config/Code/User/settings.json" "$VSCODE_SETTINGS_LINK"; then
  exit 1
fi
