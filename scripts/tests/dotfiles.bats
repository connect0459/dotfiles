#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
}

@test "home/.bashrc has valid bash syntax" {
  run bash -n "$REPO_DIR/home/.bashrc"
  [ "$status" -eq 0 ]
}

@test "home/.bash_profile has valid bash syntax" {
  run bash -n "$REPO_DIR/home/.bash_profile"
  [ "$status" -eq 0 ]
}

@test "home/.bash_aliases has valid bash syntax" {
  run bash -n "$REPO_DIR/home/.bash_aliases"
  [ "$status" -eq 0 ]
}
