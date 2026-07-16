#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/lib"
  source "$LIB_DIR/checksum.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "checksum_file_digest returns 64-char hex for a file" {
  printf 'hello' > "$TMP/hello.txt"
  run checksum_file_digest "$TMP/hello.txt"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 64 ]
}

@test "checksum_file_digest returns same checksum for same content" {
  printf 'same content' > "$TMP/a.txt"
  printf 'same content' > "$TMP/b.txt"
  run checksum_file_digest "$TMP/a.txt"
  a="$output"
  run checksum_file_digest "$TMP/b.txt"
  [ "$a" = "$output" ]
}

@test "checksum_file_digest returns different checksums for different content" {
  printf 'content A' > "$TMP/a.txt"
  printf 'content B' > "$TMP/b.txt"
  run checksum_file_digest "$TMP/a.txt"
  a="$output"
  run checksum_file_digest "$TMP/b.txt"
  [ "$a" != "$output" ]
}

@test "checksum_file_digest returns NOT_EXISTS for a missing file" {
  run checksum_file_digest "$TMP/nonexistent.txt"
  [ "$output" = "NOT_EXISTS" ]
}

@test "checksum_directory_digest returns 64-char hex for a directory" {
  printf 'content' > "$TMP/file.txt"
  run checksum_directory_digest "$TMP"
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 64 ]
}

@test "checksum_directory_digest changes when a file is added" {
  printf 'content' > "$TMP/file.txt"
  run checksum_directory_digest "$TMP"
  before="$output"
  printf 'new' > "$TMP/new.txt"
  run checksum_directory_digest "$TMP"
  [ "$before" != "$output" ]
}

@test "checksum_directory_digest returns same checksum for same structure" {
  mkdir -p "$TMP/a/sub" "$TMP/b/sub"
  printf 'same' > "$TMP/a/file.txt"
  printf 'same' > "$TMP/b/file.txt"
  printf 'nested' > "$TMP/a/sub/nested.txt"
  printf 'nested' > "$TMP/b/sub/nested.txt"
  run checksum_directory_digest "$TMP/a"
  a="$output"
  run checksum_directory_digest "$TMP/b"
  [ "$a" = "$output" ]
}

@test "checksum_directory_digest returns NOT_EXISTS for a missing directory" {
  run checksum_directory_digest "$TMP/nonexistent"
  [ "$output" = "NOT_EXISTS" ]
}

@test "checksum_of returns file checksum for a file" {
  printf 'content' > "$TMP/file.txt"
  run checksum_file_digest "$TMP/file.txt"
  expected="$output"
  run checksum_of "$TMP/file.txt"
  [ "$output" = "$expected" ]
}

@test "checksum_of returns directory checksum for a directory" {
  printf 'content' > "$TMP/file.txt"
  run checksum_directory_digest "$TMP"
  expected="$output"
  run checksum_of "$TMP"
  [ "$output" = "$expected" ]
}

@test "checksum_of returns NOT_EXISTS for a missing path" {
  run checksum_of "$TMP/nonexistent"
  [ "$output" = "NOT_EXISTS" ]
}
