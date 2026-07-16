#!/usr/bin/env bash
# Ported from sync_cmd/symlink.py.

symlink_setup() {
  local target="$1" link="$2"
  if [ -d "$link" ] && [ ! -L "$link" ]; then
    echo "symlink_setup: refusing to replace existing directory: $link" >&2
    return 1
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    rm -f "$link"
  fi
  ln -s "$target" "$link"
}
