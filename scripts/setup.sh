#!/usr/bin/env bash
# Bootstraps a fresh clone of this repo: delegates to setup-common.sh for
# shell rc file symlinking and agent config distribution, then to a
# platform-specific setup script if applicable. Safe to re-run.

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
esac

echo
pln "$(term_bold_green 'Setup complete!')"
pln "$(term_cyan 'To load the new shell configuration in this terminal, run:')"
pln "  source ~/.bash_profile"
