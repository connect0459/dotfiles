#!/usr/bin/env bash
# Bootstraps a fresh clone of this repo. Usage: setup.sh [--profile <name>].
# The profile is recorded in ~/.config/dotfiles/profile on first selection and
# reused afterwards; with neither a flag nor a recorded profile, it fails
# instead of guessing. Delegates to setup-common.sh for
# shell rc file symlinking, then to a platform-specific setup script if
# applicable, then to sync-agents.sh for agent config distribution -- run
# last so its jq dependency is already installed by the platform-specific
# script's apt/brew step. Safe to re-run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/libs/profile.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/libs/term.sh"

REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE_STATE_FILE="$HOME/.config/dotfiles/profile"

requested_profile="${DOTFILES_PROFILE:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --profile)
      if [ $# -lt 2 ]; then
        pln "$(term_red '--profile requires a profile name')" >&2
        exit 1
      fi
      requested_profile="$2"
      shift 2
      ;;
    *)
      pln "$(term_red "Unknown option: $1")" >&2
      exit 1
      ;;
  esac
done

DOTFILES_PROFILE="$(profile_resolve "$REPO_DIR/home" "$PROFILE_STATE_FILE" "$requested_profile")" || exit 1
export DOTFILES_PROFILE
if [ -z "$SETUP_DRY_RUN" ]; then
  profile_record "$PROFILE_STATE_FILE" "$DOTFILES_PROFILE"
fi

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
