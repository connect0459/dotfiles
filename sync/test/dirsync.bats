#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/lib"
  source "$LIB_DIR/dirsync.sh"
  TMP="$(mktemp -d)"
  SRC="$TMP/src"
  DST="$TMP/dst"
}

teardown() {
  rm -rf "$TMP"
}

@test "dirsync_sync copies a file from src to dst" {
  mkdir -p "$SRC"
  printf 'content' > "$SRC/file.txt"

  dirsync_sync "$SRC" "$DST"

  [ "$(cat "$DST/file.txt")" = "content" ]
}

@test "dirsync_sync handles nested directory structure" {
  mkdir -p "$SRC/sub/deep"
  printf 'deep content' > "$SRC/sub/deep/nested.txt"

  dirsync_sync "$SRC" "$DST"

  [ "$(cat "$DST/sub/deep/nested.txt")" = "deep content" ]
}

@test "dirsync_sync overwrites an existing file" {
  mkdir -p "$SRC" "$DST"
  printf 'updated' > "$SRC/file.txt"
  printf 'old' > "$DST/file.txt"

  dirsync_sync "$SRC" "$DST"

  [ "$(cat "$DST/file.txt")" = "updated" ]
}

@test "dirsync_sync deletes files not present in src" {
  mkdir -p "$SRC" "$DST"
  printf 'keep' > "$SRC/keep.txt"
  printf 'old' > "$DST/keep.txt"
  printf 'should be removed' > "$DST/remove.txt"

  dirsync_sync "$SRC" "$DST"

  [ -f "$DST/keep.txt" ]
  [ ! -e "$DST/remove.txt" ]
}

@test "dirsync_sync deletes empty dirs not present in src" {
  mkdir -p "$SRC" "$DST/empty_dir"

  dirsync_sync "$SRC" "$DST"

  [ ! -e "$DST/empty_dir" ]
}

@test "dirsync_sync works when dst does not exist yet" {
  mkdir -p "$SRC"
  printf 'content' > "$SRC/file.txt"

  dirsync_sync "$SRC" "$DST"

  [ "$(cat "$DST/file.txt")" = "content" ]
}

@test "dirsync_sync fails when src does not exist" {
  run dirsync_sync "$SRC" "$DST"
  [ "$status" -ne 0 ]
}

@test "dirsync_sync replaces a dst file with a directory when src's entry changed type" {
  mkdir -p "$SRC/foo" "$DST"
  printf 'old file content' > "$DST/foo"
  printf 'nested' > "$SRC/foo/nested.txt"

  dirsync_sync "$SRC" "$DST"

  [ -d "$DST/foo" ]
  [ "$(cat "$DST/foo/nested.txt")" = "nested" ]
}

@test "dirsync_sync replaces a dst directory with a file when src's entry changed type" {
  mkdir -p "$SRC" "$DST/foo"
  printf 'old nested' > "$DST/foo/nested.txt"
  printf 'now a file' > "$SRC/foo"

  dirsync_sync "$SRC" "$DST"

  [ -f "$DST/foo" ]
  [ ! -d "$DST/foo" ]
  [ "$(cat "$DST/foo")" = "now a file" ]
}

@test "dirsync_copy_file creates dst dir and copies content" {
  printf 'hello' > "$TMP/src.txt"

  dirsync_copy_file "$TMP/src.txt" "$TMP/sub/dst.txt"

  [ "$(cat "$TMP/sub/dst.txt")" = "hello" ]
}
