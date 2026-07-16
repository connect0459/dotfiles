#!/usr/bin/env bash
# Ported from sync_cmd/dirsync.py.

dirsync_copy_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
}

dirsync_sync() {
  local src="$1" dst="$2"
  if [ ! -d "$src" ]; then
    echo "source directory not found: $src" >&2
    return 1
  fi
  if [ -d "$dst" ]; then
    _dirsync_delete_extra_files "$src" "$dst"
    _dirsync_delete_empty_dirs "$dst"
  fi
  _dirsync_copy_tree "$src" "$dst"
}

_dirsync_delete_extra_files() {
  local src="$1" dst="$2"
  local rel
  (cd "$dst" && find . -type f | sed 's|^\./||') | while IFS= read -r rel; do
    if [ ! -e "$src/$rel" ]; then
      rm -f "$dst/$rel"
    fi
  done
}

_dirsync_delete_empty_dirs() {
  local dst="$1"
  local relpath
  (cd "$dst" && find . -mindepth 1 -type d | sed 's|^\./||') \
    | awk -F'/' '{print NF, $0}' | sort -rn | cut -d' ' -f2- \
    | while IFS= read -r relpath; do
        rmdir "$dst/$relpath" 2>/dev/null || true
      done
}

_dirsync_copy_tree() {
  local src="$1" dst="$2"
  local rel
  mkdir -p "$dst"
  (cd "$src" && find . -mindepth 1 | sed 's|^\./||' | LC_ALL=C sort) | while IFS= read -r rel; do
    if [ -d "$src/$rel" ]; then
      mkdir -p "$dst/$rel"
    else
      mkdir -p "$(dirname "$dst/$rel")"
      cp -p "$src/$rel" "$dst/$rel"
    fi
  done
}
