#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/libs"
  source "$LIB_DIR/profile.sh"
  TMP="$(mktemp -d)"
  PROFILES_DIR="$TMP/home"
  STATE_FILE="$TMP/state/profile"
  mkdir -p "$PROFILES_DIR/common" "$PROFILES_DIR/work" "$PROFILES_DIR/personal"
}

teardown() {
  rm -rf "$TMP"
}

@test "profile_list prints each profile directory name on its own line, sorted" {
  run profile_list "$PROFILES_DIR"

  [ "$status" -eq 0 ]
  [ "$output" = "$(printf 'personal\nwork')" ]
}

@test "profile_list excludes the shared common layer" {
  run profile_list "$PROFILES_DIR"

  [[ "$output" != *"common"* ]]
}

@test "profile_list ignores plain files in the profiles directory" {
  touch "$PROFILES_DIR/README.md"

  run profile_list "$PROFILES_DIR"

  [ "$output" = "$(printf 'personal\nwork')" ]
}

@test "profile_resolve prints the requested profile without touching the state file" {
  run profile_resolve "$PROFILES_DIR" "$STATE_FILE" work

  [ "$status" -eq 0 ]
  [ "$output" = "work" ]
  [ ! -e "$STATE_FILE" ]
}

@test "profile_record writes the profile name to the state file, creating parent directories" {
  profile_record "$STATE_FILE" work

  [ "$(cat "$STATE_FILE")" = "work" ]
}

@test "profile_record overwrites a previously recorded profile" {
  profile_record "$STATE_FILE" work
  profile_record "$STATE_FILE" personal

  [ "$(cat "$STATE_FILE")" = "personal" ]
}

@test "profile_resolve falls back to the profile recorded in the state file when none is requested" {
  mkdir -p "$(dirname "$STATE_FILE")"
  echo personal > "$STATE_FILE"

  run profile_resolve "$PROFILES_DIR" "$STATE_FILE" ""

  [ "$status" -eq 0 ]
  [ "$output" = "personal" ]
}

@test "profile_resolve prints only the profile name when SIGPIPE is ignored and many profiles follow the match" {
  trap '' PIPE
  for i in $(seq 1 20); do
    mkdir "$PROFILES_DIR/zz-$i"
  done

  run profile_resolve "$PROFILES_DIR" "$STATE_FILE" personal

  [ "$status" -eq 0 ]
  [ "$output" = "personal" ]
}

@test "profile_resolve lets an explicit request override the recorded profile" {
  mkdir -p "$(dirname "$STATE_FILE")"
  echo personal > "$STATE_FILE"

  run profile_resolve "$PROFILES_DIR" "$STATE_FILE" work

  [ "$output" = "work" ]
}

@test "profile_resolve fails and lists the valid profiles when nothing is requested or recorded" {
  run --separate-stderr profile_resolve "$PROFILES_DIR" "$STATE_FILE" ""

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"No profile selected"* ]]
  [[ "$stderr" == *"personal"* ]]
  [[ "$stderr" == *"work"* ]]
  [ ! -e "$STATE_FILE" ]
}

@test "profile_resolve rejects an unknown profile name without touching the state file" {
  run --separate-stderr profile_resolve "$PROFILES_DIR" "$STATE_FILE" bogus

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"Unknown profile: bogus"* ]]
  [[ "$stderr" == *"personal"* ]]
  [ ! -e "$STATE_FILE" ]
}

@test "profile_resolve rejects a recorded profile that no longer exists" {
  mkdir -p "$(dirname "$STATE_FILE")"
  echo retired > "$STATE_FILE"

  run --separate-stderr profile_resolve "$PROFILES_DIR" "$STATE_FILE" ""

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"Unknown profile: retired"* ]]
}

@test "profile_resolve rejects the shared common layer as a profile" {
  run --separate-stderr profile_resolve "$PROFILES_DIR" "$STATE_FILE" common

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"Unknown profile: common"* ]]
}

@test "profile_resolve rejects names that could escape the profiles directory" {
  run --separate-stderr profile_resolve "$PROFILES_DIR" "$STATE_FILE" "../work"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"Unknown profile: ../work"* ]]
}
