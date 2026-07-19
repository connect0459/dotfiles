#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/libs"
  source "$LIB_DIR/dry_run.sh"
  unset SETUP_DRY_RUN
  unset SETUP_SKIP_NETWORK_INSTALLS
}

@test "skip_network_install returns false when neither flag is set" {
  run skip_network_install
  [ "$status" -eq 1 ]
}

@test "skip_network_install returns true when SETUP_DRY_RUN is set" {
  export SETUP_DRY_RUN=1
  run skip_network_install
  [ "$status" -eq 0 ]
}

@test "skip_network_install returns true when SETUP_SKIP_NETWORK_INSTALLS is set" {
  export SETUP_SKIP_NETWORK_INSTALLS=1
  run skip_network_install
  [ "$status" -eq 0 ]
}

@test "skip_network_install returns true when both flags are set" {
  export SETUP_DRY_RUN=1
  export SETUP_SKIP_NETWORK_INSTALLS=1
  run skip_network_install
  [ "$status" -eq 0 ]
}
