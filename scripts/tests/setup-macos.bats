#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_MACOS_SH="$SCRIPTS_DIR/setup-macos.sh"
  TMP="$(mktemp -d)"
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
  export HOME="$TMP/home"
  # Skips only the Brewfile install, so tests can exercise real symlinking
  # without SETUP_DRY_RUN also suppressing it.
  export SETUP_SKIP_NETWORK_INSTALLS=1
  mkdir -p "$HOME"
  export DOTFILES_PROFILE=work
}

teardown() {
  rm -rf "$TMP"
}

@test "setup-macos.sh succeeds in dry-run mode" {
  export SETUP_DRY_RUN=1
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
}

@test "setup-macos.sh reports dry-run when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN]"* ]]
}

@test "setup-macos.sh reports the Brewfile path in the dry-run message" {
  export SETUP_DRY_RUN=1
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install from $REPO_DIR/home/work/Brewfile"* ]]
}

@test "setup-macos.sh skips package installation without failing when the profile has no Brewfile" {
  export DOTFILES_PROFILE=personal
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No Brewfile for profile personal, skipping"* ]]
}

@test "setup-macos.sh fails when no profile is selected" {
  unset DOTFILES_PROFILE
  run "$SETUP_MACOS_SH"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No profile selected"* ]]
}

@test "setup-macos.sh reports dry-run for Ruby install via rbenv when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install Ruby 3.4.5 via rbenv and set it as the global default"* ]]
}

@test "setup-macos.sh displays instructions for setting login shell when bash is installed" {
  FAKE_PREFIX="$TMP/homebrew"
  mkdir -p "$FAKE_PREFIX/bin"
  printf '#!/bin/sh\n' > "$FAKE_PREFIX/bin/bash"
  chmod +x "$FAKE_PREFIX/bin/bash"
  mkdir -p "$TMP/fakebin"
  printf '#!/bin/sh\necho "%s"\n' "$FAKE_PREFIX" > "$TMP/fakebin/brew"
  chmod +x "$TMP/fakebin/brew"
  export PATH="$TMP/fakebin:$PATH"

  export SHELL="/bin/bash"
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"set it as your login shell"* ]]
}

@test "setup-macos.sh symlinks VS Code settings.json into HOME, creating parent dirs" {
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/Library/Application Support/Code/User/settings.json" ]
  [ "$(readlink "$HOME/Library/Application Support/Code/User/settings.json")" = "$REPO_DIR/home/common/dot_config/Code/User/settings.json" ]
}

@test "setup-macos.sh prints a dry-run message for VS Code settings.json and does not create it when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_MACOS_SH"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/Library/Application Support/Code/User/settings.json" ]
  [[ "$output" == *"[DRY RUN] Would symlink $HOME/Library/Application Support/Code/User/settings.json -> $REPO_DIR/home/common/dot_config/Code/User/settings.json"* ]]
}
