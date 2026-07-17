#!/usr/bin/env bash
# macOS-specific setup: installs dependencies from Brewfile and configures bash.
# Safe to re-run.

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/sync-agents/libs/term.sh"

if ! command -v brew &> /dev/null; then
  pln "$(term_red 'brew not found. Please install Homebrew from https://brew.sh')" >&2
  exit 1
fi

if [ -f "$REPO_DIR/home/Brewfile" ]; then
  pln "$(term_bold 'Installing macOS dependencies from Brewfile')"

  if [ -n "$SETUP_MACOS_DRY_RUN" ]; then
    pln "$(term_cyan '[DRY RUN] Would install from' "$REPO_DIR/home/Brewfile")"
  else
    brew bundle install --file="$REPO_DIR/home/Brewfile"
  fi
else
  pln "$(term_red 'Brewfile not found at' "$REPO_DIR/home/Brewfile")" >&2
  exit 1
fi

pln
pln "$(term_bold 'Installing mise-managed tools')"

if [ -n "$SETUP_MACOS_DRY_RUN" ]; then
  pln "$(term_cyan '[DRY RUN] Would install mise tools from' "$REPO_DIR/.mise.toml")"
else
  mise install -C "$REPO_DIR"
fi

pln
pln "$(term_bold 'Installing Rust toolchain (rustup)')"

if command -v rustup &> /dev/null; then
  pln "$(term_cyan 'rustup already installed, skipping')"
elif [ -n "$SETUP_MACOS_DRY_RUN" ]; then
  pln "$(term_cyan '[DRY RUN] Would install rustup from https://sh.rustup.rs')"
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

HOMEBREW_BASH="$(brew --prefix)/bin/bash"
if [ -x "$HOMEBREW_BASH" ] && [ "$SHELL" != "$HOMEBREW_BASH" ]; then
  pln
  pln "$(term_bold 'Homebrew bash installed.')"
  pln "$(term_cyan 'To set it as your login shell, run:')"
  pln "  echo $HOMEBREW_BASH | sudo tee -a /etc/shells"
  pln "  chsh -s $HOMEBREW_BASH"
fi
