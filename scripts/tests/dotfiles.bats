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

@test "home/.bash_profile does not error or add /opt/homebrew paths when Homebrew is not installed" {
  if [ -e /opt/homebrew ]; then
    skip "Homebrew is installed on this host; the absence guard cannot be exercised"
  fi

  TMP="$(mktemp -d)"
  HOME_DIR="$TMP/home"
  mkdir -p "$HOME_DIR/.local/bin" "$HOME_DIR/.cargo"
  touch "$HOME_DIR/.bashrc" "$HOME_DIR/.local/bin/env" "$HOME_DIR/.cargo/env"

  run env -i HOME="$HOME_DIR" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/.bash_profile' && echo \"PATH=\$PATH\""

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file or directory"* ]]
  [[ "$output" != *"/opt/homebrew"* ]]
}
