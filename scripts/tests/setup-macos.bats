#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_MACOS_SH="$SCRIPTS_DIR/setup-macos.sh"
  TMP="$(mktemp -d)"
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
  export HOME="$TMP/home"
  export SETUP_DRY_RUN=1
  mkdir -p "$HOME"
}

teardown() {
  rm -rf "$TMP"
}

@test "setup-macos.sh succeeds in dry-run mode" {
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
}

@test "setup-macos.sh reports dry-run when SETUP_DRY_RUN is set" {
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN]"* ]]
}

@test "setup-macos.sh reports the Brewfile path in the dry-run message" {
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install from $REPO_DIR/home/Brewfile"* ]]
}

@test "setup-macos.sh displays instructions for setting login shell when bash is installed" {
  if ! command -v brew &> /dev/null; then
    skip "brew not installed"
  fi

  export SHELL="/bin/bash"
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"set it as your login shell"* ]]
}

@test "setup-macos.sh symlinks VS Code settings.json into HOME, creating parent dirs" {
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/Library/Application Support/Code/User/settings.json" ]
  [ "$(readlink "$HOME/Library/Application Support/Code/User/settings.json")" = "$REPO_DIR/home/dot_config/Code/User/settings.json" ]
}
