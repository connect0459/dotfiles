#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_LINUX_SH="$SCRIPTS_DIR/setup-linux.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  # Skips only the network-fetching installs (rbenv/ruby-build/ruby), so
  # tests can exercise real symlinking without SETUP_DRY_RUN also
  # suppressing it.
  export SETUP_SKIP_NETWORK_INSTALLS=1
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

@test "setup-linux.sh prints a dry-run message and does not create the symlink when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_LINUX_SH"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/Code/User/settings.json" ]
  [[ "$output" == *"[DRY RUN] Would symlink $HOME/.config/Code/User/settings.json -> $REPO_DIR/home/dot_config/Code/User/settings.json"* ]]
}

@test "setup-linux.sh reports dry-run for apt dependencies when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_LINUX_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would apt-get install: build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc patch libreadline6-dev libncurses5-dev libgdbm6 libgdbm-dev libdb-dev"* ]]
}

@test "setup-linux.sh fails clearly instead of running apt-get when APTFILE does not exist" {
  export APTFILE="$TMP/does-not-exist"
  run "$SETUP_LINUX_SH"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Failed to read apt package list from $TMP/does-not-exist"* ]]
}

@test "setup-linux.sh fails clearly instead of running apt-get when APTFILE has no packages" {
  printf '# nothing but comments\n' > "$TMP/EmptyAptfile"
  export APTFILE="$TMP/EmptyAptfile"
  run "$SETUP_LINUX_SH"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No apt packages found in $TMP/EmptyAptfile"* ]]
}

@test "setup-linux.sh reports dry-run for rbenv install when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_LINUX_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would clone rbenv and ruby-build into $HOME/.rbenv"* ]]
}

@test "setup-linux.sh reports dry-run for Ruby install via rbenv when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_LINUX_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install Ruby 3.4.5 via rbenv and set it as the global default"* ]]
}
