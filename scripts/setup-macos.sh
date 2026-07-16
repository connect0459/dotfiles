#!/usr/bin/env bash
# macOS-specific setup: installs dependencies from Brewfile.
# Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/sync-agents/libs/term.sh"

if ! command -v brew &> /dev/null; then
  pln "$(term_red 'brew not found. Please install Homebrew from https://brew.sh')" >&2
  exit 1
fi

pln "$(term_bold 'Installing macOS dependencies from Brewfile')"

if [ -f "$REPO_DIR/home/Brewfile" ]; then
  brew bundle install --file="$REPO_DIR/home/Brewfile"
else
  pln "$(term_red 'Brewfile not found at' "$REPO_DIR/home/Brewfile")" >&2
  exit 1
fi
