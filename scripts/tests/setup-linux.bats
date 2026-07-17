#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_LINUX_SH="$SCRIPTS_DIR/setup-linux.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  mkdir -p "$HOME"
}

teardown() {
  rm -rf "$TMP"
}

@test "setup-linux.sh symlinks VS Code settings.json into HOME, creating parent dirs" {
  run "$SETUP_LINUX_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/Code/User/settings.json" ]
  [ "$(readlink "$HOME/.config/Code/User/settings.json")" = "$REPO_DIR/home/dot_config/Code/User/settings.json" ]
}

@test "setup-linux.sh backs up a pre-existing real settings.json before symlinking over it" {
  mkdir -p "$HOME/.config/Code/User"
  printf 'local content' > "$HOME/.config/Code/User/settings.json"

  run "$SETUP_LINUX_SH"

  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/Code/User/settings.json" ]
  [ -f "$HOME/.config/Code/User/settings.json.bak" ]
  [ "$(cat "$HOME/.config/Code/User/settings.json.bak")" = "local content" ]
}

@test "setup-linux.sh is safe to re-run" {
  run "$SETUP_LINUX_SH"
  [ "$status" -eq 0 ]

  run "$SETUP_LINUX_SH"

  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/Code/User/settings.json" ]
  [ ! -e "$HOME/.config/Code/User/settings.json.bak" ]
}
