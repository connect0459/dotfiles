#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/libs"
  source "$LIB_DIR/apt.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "apt_packages_from_file prints each package on its own line" {
  printf 'foo\nbar\nbaz\n' > "$TMP/Aptfile"

  run apt_packages_from_file "$TMP/Aptfile"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "foo" ]
  [ "${lines[1]}" = "bar" ]
  [ "${lines[2]}" = "baz" ]
}

@test "apt_packages_from_file skips comment lines" {
  printf '# a comment\nfoo\n# another\nbar\n' > "$TMP/Aptfile"

  run apt_packages_from_file "$TMP/Aptfile"

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "foo" ]
  [ "${lines[1]}" = "bar" ]
}

@test "apt_packages_from_file skips blank lines" {
  printf 'foo\n\n   \nbar\n' > "$TMP/Aptfile"

  run apt_packages_from_file "$TMP/Aptfile"

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "foo" ]
  [ "${lines[1]}" = "bar" ]
}

@test "apt_packages_from_file ignores indented comment lines" {
  printf '  # indented comment\nfoo\n' > "$TMP/Aptfile"

  run apt_packages_from_file "$TMP/Aptfile"

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "foo" ]
}
