#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/lib"
  source "$LIB_DIR/symlink.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "symlink_setup creates a symlink pointing to target" {
  printf 'content' > "$TMP/target.txt"

  symlink_setup "$TMP/target.txt" "$TMP/link.txt"

  [ -L "$TMP/link.txt" ]
  [ "$(cat "$TMP/link.txt")" = "content" ]
}

@test "symlink_setup replaces an existing symlink pointing elsewhere" {
  printf 'old' > "$TMP/old.txt"
  printf 'new' > "$TMP/new.txt"
  ln -s "$TMP/old.txt" "$TMP/link.txt"

  symlink_setup "$TMP/new.txt" "$TMP/link.txt"

  [ -L "$TMP/link.txt" ]
  [ "$(cat "$TMP/link.txt")" = "new" ]
}

@test "symlink_setup replaces a regular file with a symlink" {
  printf 'target content' > "$TMP/target.txt"
  printf 'regular file' > "$TMP/link.txt"

  symlink_setup "$TMP/target.txt" "$TMP/link.txt"

  [ -L "$TMP/link.txt" ]
  [ "$(cat "$TMP/link.txt")" = "target content" ]
}
