#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
  SETUP_COMMON_SH="$SCRIPTS_DIR/setup-common.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  # Skips only the network-fetching installs (rustup/nvm), so tests can
  # exercise real symlinking without SETUP_DRY_RUN also suppressing it.
  export SETUP_SKIP_NETWORK_INSTALLS=1
  mkdir -p "$HOME"
  # Strip user-level toolchain dirs (~/.cargo/bin, ~/.local/bin, rbenv
  # shims, ...) so the new "already installed" existence checks see a clean
  # machine, not whatever happens to be on the developer's real PATH.
  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

teardown() {
  rm -rf "$TMP"
}

@test "setup-common.sh symlinks .bashrc into HOME" {
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ "$(readlink "$HOME/.bashrc")" = "$REPO_DIR/home/.bashrc" ]
}

@test "setup-common.sh symlinks .bash_profile into HOME" {
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bash_profile" ]
  [ "$(readlink "$HOME/.bash_profile")" = "$REPO_DIR/home/.bash_profile" ]
}

@test "setup-common.sh symlinks .bash_aliases into HOME" {
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.bash_aliases" ]
  [ "$(readlink "$HOME/.bash_aliases")" = "$REPO_DIR/home/.bash_aliases" ]
}

@test "setup-common.sh symlinks .config/git/ignore into HOME, creating parent dirs" {
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/git/ignore" ]
  [ "$(readlink "$HOME/.config/git/ignore")" = "$REPO_DIR/home/dot_config/git/ignore" ]
}

@test "setup-common.sh backs up a pre-existing real .bashrc before symlinking over it" {
  printf 'local content' > "$HOME/.bashrc"

  run "$SETUP_COMMON_SH"

  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ -f "$HOME/.bashrc.bak" ]
  [ "$(cat "$HOME/.bashrc.bak")" = "local content" ]
}

@test "setup-common.sh delegates to sync-agents.sh for coding-agent config distribution" {
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ -f "$HOME/.agents/AGENTS.md" ]
}

@test "setup-common.sh reports dry-run for rustup install when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install rustup from https://sh.rustup.rs"* ]]
}

@test "setup-common.sh reports dry-run for nvm install when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install nvm v0.40.5 from https://github.com/nvm-sh/nvm"* ]]
}

@test "setup-common.sh reports dry-run for Node install via nvm when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would install Node 24.15.0 via nvm and set it as the default"* ]]
}

@test "setup-common.sh prints a dry-run message for symlinking a dotfile and does not create it when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.bashrc" ]
  [[ "$output" == *"[DRY RUN] Would symlink $HOME/.bashrc -> $REPO_DIR/home/.bashrc"* ]]
}

@test "setup-common.sh is safe to re-run" {
  run "$SETUP_COMMON_SH"
  [ "$status" -eq 0 ]

  run "$SETUP_COMMON_SH"

  [ "$status" -eq 0 ]
  [ -L "$HOME/.bashrc" ]
  [ ! -e "$HOME/.bashrc.bak" ]
}

@test "setup-common.sh skips rustup install and reports already-installed when rustup is already on PATH" {
  FAKE_BIN="$TMP/fakebin"
  mkdir -p "$FAKE_BIN"
  printf '#!/usr/bin/env bash\n' > "$FAKE_BIN/rustup"
  chmod +x "$FAKE_BIN/rustup"
  export PATH="$FAKE_BIN:$PATH"

  run "$SETUP_COMMON_SH"

  [ "$status" -eq 0 ]
  [[ "$output" == *"rustup already installed, skipping"* ]]
  [[ "$output" != *"Would install rustup"* ]]
}

@test "setup-common.sh skips nvm install and reports already-installed when nvm is already installed" {
  mkdir -p "$HOME/.nvm"
  printf '# stub nvm.sh\n' > "$HOME/.nvm/nvm.sh"

  run "$SETUP_COMMON_SH"

  [ "$status" -eq 0 ]
  [[ "$output" == *"nvm already installed, skipping"* ]]
  [[ "$output" != *"Would install nvm v0.40.5"* ]]
}
