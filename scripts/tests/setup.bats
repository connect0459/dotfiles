#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_SH="$SCRIPTS_DIR/setup.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  # Skips only the network-fetching installs, so tests can exercise real
  # symlinking without SETUP_DRY_RUN also suppressing it.
  export SETUP_SKIP_NETWORK_INSTALLS=1
  mkdir -p "$HOME"
}

teardown() {
  rm -rf "$TMP"
}

@test "setup.sh delegates to setup-common.sh and platform-specific script on macOS" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ "$(readlink "$HOME/.bashrc")" = "$REPO_DIR/home/.bashrc" ]
}

@test "setup.sh symlinks .bash_profile into HOME" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bash_profile" ]
  [ "$(readlink "$HOME/.bash_profile")" = "$REPO_DIR/home/.bash_profile" ]
}

@test "setup.sh symlinks .bash_aliases into HOME" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bash_aliases" ]
  [ "$(readlink "$HOME/.bash_aliases")" = "$REPO_DIR/home/.bash_aliases" ]
}

@test "setup.sh symlinks .config/git/ignore into HOME, creating parent dirs" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/git/ignore" ]
  [ "$(readlink "$HOME/.config/git/ignore")" = "$REPO_DIR/home/dot_config/git/ignore" ]
}

@test "setup.sh backs up a pre-existing real .bashrc before symlinking over it" {
  printf 'local content' > "$HOME/.bashrc"

  run "$SETUP_SH"

  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ -f "$HOME/.bashrc.bak" ]
  [ "$(cat "$HOME/.bashrc.bak")" = "local content" ]
}

@test "setup.sh delegates to sync-agents.sh for coding-agent config distribution" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ -f "$HOME/.agents/AGENTS.md" ]
}

@test "setup.sh installs apt dependencies before syncing coding-agent configuration on Linux" {
  if [ "$(uname -s)" != "Linux" ]; then
    skip "Linux only — setup.sh delegates to setup-macos.sh on this platform"
  fi

  run "$SETUP_SH"
  [ "$status" -eq 0 ]

  apt_line="$(printf '%s\n' "$output" | grep -n 'Would apt-get install' | head -1 | cut -d: -f1)"
  sync_line="$(printf '%s\n' "$output" | grep -n 'Coding agents configuration sync tool' | head -1 | cut -d: -f1)"

  [ -n "$apt_line" ]
  [ -n "$sync_line" ]
  [ "$apt_line" -lt "$sync_line" ]
}

@test "setup.sh installs Brewfile dependencies before syncing coding-agent configuration on macOS" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "macOS only — setup.sh delegates to setup-linux.sh on this platform"
  fi

  run "$SETUP_SH"
  [ "$status" -eq 0 ]

  brew_line="$(printf '%s\n' "$output" | grep -n 'Installing macOS dependencies from Brewfile' | head -1 | cut -d: -f1)"
  sync_line="$(printf '%s\n' "$output" | grep -n 'Coding agents configuration sync tool' | head -1 | cut -d: -f1)"

  [ -n "$brew_line" ]
  [ -n "$sync_line" ]
  [ "$brew_line" -lt "$sync_line" ]
}

@test "setup.sh symlinks VS Code settings.json into HOME on macOS" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "macOS only — setup.sh delegates to setup-linux.sh on this platform"
  fi

  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/Library/Application Support/Code/User/settings.json" ]
  [ "$(readlink "$HOME/Library/Application Support/Code/User/settings.json")" = "$REPO_DIR/home/dot_config/Code/User/settings.json" ]
}

@test "setup.sh prints a reminder to reload the shell config after completing" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"source ~/.bash_profile"* ]]
}

@test "setup.sh is safe to re-run" {
  run "$SETUP_SH"
  [ "$status" -eq 0 ]

  run "$SETUP_SH"

  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ ! -e "$HOME/.bashrc.bak" ]
}
