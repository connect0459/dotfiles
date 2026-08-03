#!/usr/bin/env bats

setup() {
  SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/colima-cleanup.sh"
  TMP="$(mktemp -d)"
  FAKE_BIN="$TMP/bin"
  mkdir -p "$FAKE_BIN"
  CALL_LOG="$TMP/colima-calls.log"
  : > "$CALL_LOG"

  # Fake colima: logs every invocation, and answers `status` based on
  # whether the requested profile is "default" (simulating "running").
  cat > "$FAKE_BIN/colima" <<'FAKE'
#!/usr/bin/env bash
echo "$@" >> "$CALL_LOG"
if [ "$1" = "status" ]; then
  profile="default"
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --profile|-p) profile="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ "$profile" = "default" ]
  exit $?
fi
exit 0
FAKE
  chmod +x "$FAKE_BIN/colima"

  export CALL_LOG
  unset SETUP_DRY_RUN
}

teardown() {
  rm -rf "$TMP"
}

@test "colima-cleanup.sh --help prints usage and exits 0" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "colima-cleanup.sh fails with a clear error when colima is not installed" {
  export PATH="/usr/bin:/bin"
  run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"colima"* ]]
}

@test "colima-cleanup.sh fails when the target profile is not running" {
  export PATH="$FAKE_BIN:$PATH"
  run "$SCRIPT" --profile not-running
  [ "$status" -eq 1 ]
  [[ "$output" == *"not-running"* ]]
  ! grep -q "ssh" "$CALL_LOG"
}

@test "colima-cleanup.sh reports dry-run commands without invoking colima ssh" {
  export PATH="$FAKE_BIN:$PATH"
  export SETUP_DRY_RUN=1
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would run: colima ssh --profile default -- docker system prune -a -f"* ]]
  [[ "$output" == *"[DRY RUN] Would run: colima ssh --profile default -- sudo fstrim -av"* ]]
  ! grep -q "ssh" "$CALL_LOG"
}

@test "colima-cleanup.sh dry-run honors a custom --profile" {
  export PATH="$FAKE_BIN:$PATH"
  export SETUP_DRY_RUN=1
  run "$SCRIPT" --profile work
  [ "$status" -eq 0 ]
  [[ "$output" == *"colima ssh --profile work -- docker system prune -a -f"* ]]
}

@test "colima-cleanup.sh runs prune then fstrim via colima ssh for a running profile" {
  export PATH="$FAKE_BIN:$PATH"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q -- "--profile default -- docker system prune -a -f" "$CALL_LOG"
  grep -q -- "--profile default -- sudo fstrim -av" "$CALL_LOG"
}

@test "colima-cleanup.sh fails and does not run fstrim when docker prune fails" {
  export PATH="$FAKE_BIN:$PATH"
  cat > "$FAKE_BIN/colima" <<'FAKE'
#!/usr/bin/env bash
echo "$@" >> "$CALL_LOG"
case "$*" in
  status*) exit 0 ;;
  *"docker system prune"*) exit 1 ;;
  *) exit 0 ;;
esac
FAKE
  chmod +x "$FAKE_BIN/colima"

  run "$SCRIPT"
  [ "$status" -ne 0 ]
  ! grep -q "fstrim" "$CALL_LOG"
}

@test "colima-cleanup.sh exits with an error instead of hanging when --profile has no value" {
  run "$SCRIPT" --profile
  [ "$status" -eq 1 ]
  [[ "$output" == *"--profile"* ]]
}
