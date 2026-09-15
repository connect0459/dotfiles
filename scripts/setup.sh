#!/usr/bin/env bash
# Bootstraps a fresh clone of this repo: delegates to setup-common.sh for
# shell rc file symlinking, then to a platform-specific setup script if
# applicable, then to sync-agents.sh for agent config distribution -- run
# last so its jq dependency is already installed by the platform-specific
# script's apt/brew step. Safe to re-run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/libs/term.sh"

"$SCRIPT_DIR/setup-common.sh" || exit 1

OS="$(uname -s)"
case "$OS" in
  Darwin)
    if [ -x "$SCRIPT_DIR/setup-macos.sh" ]; then
      "$SCRIPT_DIR/setup-macos.sh" || exit 1
    fi
    ;;
  Linux)
    if [ -x "$SCRIPT_DIR/setup-linux.sh" ]; then
      "$SCRIPT_DIR/setup-linux.sh" || exit 1
    fi
    ;;
esac

echo
"$SCRIPT_DIR/sync-agents/sync-agents.sh" || exit 1

echo
pln "$(term_bold_green 'Setup complete!')"
pln "$(term_cyan 'To load the new shell configuration in this terminal, run:')"
pln "  source ~/.bash_profile"
