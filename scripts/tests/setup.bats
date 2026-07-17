#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_SH="$SCRIPTS_DIR/setup.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  export SETUP_DRY_RUN=1
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

@test "setup.sh symlinks VS Code settings.json into HOME on macOS" {
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
