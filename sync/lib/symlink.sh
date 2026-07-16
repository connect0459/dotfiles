#!/usr/bin/env bash
# Ported from sync_cmd/symlink.py.

symlink_setup() {
  local target="$1" link="$2"
  if [ -e "$link" ] || [ -L "$link" ]; then
    rm -f "$link"
  fi
  ln -s "$target" "$link"
}
