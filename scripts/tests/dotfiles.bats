#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
}

@test "home/common/.bashrc has valid bash syntax" {
  run bash -n "$REPO_DIR/home/common/.bashrc"
  [ "$status" -eq 0 ]
}

@test "home/work/bashrc.sh has valid bash syntax" {
  run bash -n "$REPO_DIR/home/work/bashrc.sh"
  [ "$status" -eq 0 ]
}

@test "home/common/.bashrc loads the profile-specific ~/.config/dotfiles/profile.sh" {
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/.config/dotfiles"
  echo "export PROFILE_MARKER=loaded" > "$TMP/.config/dotfiles/profile.sh"
  sed -n '/^# profile-specific shell config/,/^fi$/p' "$REPO_DIR/home/common/.bashrc" > "$TMP/snippet.sh"

  run env -i HOME="$TMP" PATH="/usr/bin:/bin" \
    bash -c "source '$TMP/snippet.sh' && echo \$PROFILE_MARKER"

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [ "$output" = "loaded" ]
}

@test "home/common/.bashrc does not contain work-only tool setup shared across profiles" {
  run grep -E 'Android|\.rd/bin|ghcup' "$REPO_DIR/home/common/.bashrc"
  [ "$status" -ne 0 ]
}

@test "home/work/bashrc.sh adds the Android SDK tools to PATH" {
  TMP="$(mktemp -d)"

  run env -i HOME="$TMP" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/work/bashrc.sh' && echo \$PATH"

  rm -rf "$TMP"

  [[ "$output" == *"$TMP/Library/Android/sdk/platform-tools"* ]]
  [[ "$output" == *"$TMP/Library/Android/sdk/emulator"* ]]
}

@test "home/common/.bash_profile has valid bash syntax" {
  run bash -n "$REPO_DIR/home/common/.bash_profile"
  [ "$status" -eq 0 ]
}

@test "home/common/.bash_aliases has valid bash syntax" {
  run bash -n "$REPO_DIR/home/common/.bash_aliases"
  [ "$status" -eq 0 ]
}

@test "home/common/.bash_profile does not error or add /opt/homebrew paths when Homebrew is not installed" {
  if [ -e /opt/homebrew ]; then
    skip "Homebrew is installed on this host; the absence guard cannot be exercised"
  fi

  TMP="$(mktemp -d)"
  HOME_DIR="$TMP/home"
  mkdir -p "$HOME_DIR/.local/bin" "$HOME_DIR/.cargo"
  touch "$HOME_DIR/.bashrc" "$HOME_DIR/.local/bin/env" "$HOME_DIR/.cargo/env"

  run env -i HOME="$HOME_DIR" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/common/.bash_profile' && echo \"PATH=\$PATH\""

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file or directory"* ]]
  [[ "$output" != *"/opt/homebrew"* ]]
}

@test "home/common/.bash_profile does not error when ~/.local/bin/env does not exist" {
  TMP="$(mktemp -d)"
  HOME_DIR="$TMP/home"
  mkdir -p "$HOME_DIR/.cargo"
  touch "$HOME_DIR/.bashrc" "$HOME_DIR/.cargo/env"

  run env -i HOME="$HOME_DIR" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/common/.bash_profile'"

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file or directory"* ]]
}

@test "home/common/.bash_profile does not error when ~/.cargo/env does not exist" {
  TMP="$(mktemp -d)"
  HOME_DIR="$TMP/home"
  mkdir -p "$HOME_DIR/.local/bin"
  touch "$HOME_DIR/.bashrc" "$HOME_DIR/.local/bin/env"

  run env -i HOME="$HOME_DIR" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/common/.bash_profile'"

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file or directory"* ]]
}

@test "home/common/.bash_aliases loads aliases defined in ~/.bash_aliases.local" {
  TMP="$(mktemp -d)"
  echo "alias local_only_alias='echo local'" > "$TMP/.bash_aliases.local"

  run env -i HOME="$TMP" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/common/.bash_aliases' && alias local_only_alias"

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [[ "$output" == *"local_only_alias"* ]]
}

@test "home/common/.bash_aliases does not error when ~/.bash_aliases.local does not exist" {
  TMP="$(mktemp -d)"

  run env -i HOME="$TMP" PATH="/usr/bin:/bin" \
    bash -c "source '$REPO_DIR/home/common/.bash_aliases'"

  rm -rf "$TMP"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "home/common/dot_config/cabal/config points hackage.haskell.org at an https URL without TUF verification" {
  run grep -E '^[[:space:]]+(url: https://hackage\.haskell\.org/|secure: False)$' "$REPO_DIR/home/common/dot_config/cabal/config"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
}
