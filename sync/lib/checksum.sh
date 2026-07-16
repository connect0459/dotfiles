#!/usr/bin/env bash
# Content-addressable digests used to detect drift before overwriting a synced file/dir.
# Ported from sync_cmd/checksum.py; digest values are not required to match the
# Python implementation byte-for-byte, only its equality/inequality semantics.

checksum_file_digest() {
  local path="$1"
  if [ ! -f "$path" ]; then
    printf 'NOT_EXISTS'
    return 0
  fi
  shasum -a 256 "$path" | awk '{print $1}'
}

checksum_directory_digest() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    printf 'NOT_EXISTS'
    return 0
  fi

  local rel
  (
    cd "$dir" || exit 1
    find . -type f | sed 's|^\./||' | LC_ALL=C sort
  ) | while IFS= read -r rel; do
    printf '%s' "$rel"
    checksum_file_digest "$dir/$rel"
  done | shasum -a 256 | awk '{print $1}'
}

checksum_of() {
  local path="$1"
  if [ ! -e "$path" ]; then
    printf 'NOT_EXISTS'
    return 0
  fi
  if [ -d "$path" ]; then
    checksum_directory_digest "$path"
  else
    checksum_file_digest "$path"
  fi
}
