#!/usr/bin/env bash
# Ported from sync_cmd/symlink.py, extended with a backup step: this is
# wired up against a real, live ~/.claude/CLAUDE.md by sync.sh, so replacing
# a pre-existing real file (not yet a symlink) needs to be recoverable
# rather than a silent, unrecoverable loss of whatever it used to contain.

symlink_setup() {
  local target="$1" link="$2"
  if [ -d "$link" ] && [ ! -L "$link" ]; then
    echo "symlink_setup: refusing to replace existing directory: $link" >&2
    return 1
  fi
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    cp -p "$link" "$link.bak"
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    rm -f "$link"
  fi
  ln -s "$target" "$link"
}
