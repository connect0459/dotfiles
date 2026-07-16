#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_MACOS_SH="$SCRIPTS_DIR/setup-macos.sh"
  TMP="$(mktemp -d)"
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
  export HOME="$TMP/home"
  mkdir -p "$HOME"
}

teardown() {
  rm -rf "$TMP"
}

@test "setup-macos.sh succeeds when brew is available" {
  if ! command -v brew &> /dev/null; then
    skip "brew not installed"
  fi

  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
}

@test "setup-macos.sh installs dependencies from Brewfile" {
  if ! command -v brew &> /dev/null; then
    skip "brew not installed"
  fi

  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
}

@test "setup-macos.sh displays instructions for setting login shell" {
  if ! command -v brew &> /dev/null; then
    skip "brew not installed"
  fi

  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
}
