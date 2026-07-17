#!/usr/bin/env bash
# Ported from sync_cmd/symlink.py, extended with a backup step: this is
# wired up against a real, live ~/.claude/CLAUDE.md by sync-agents.sh, so replacing
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

# symlink_setup_reporting target link
# Wraps symlink_setup for the top-level bootstrap scripts: creates link's
# parent directory first, then prints the resulting mapping (or, if
# SETUP_DRY_RUN is set, prints what it would do instead of touching the
# filesystem at all). Returns non-zero without exiting so the caller decides
# how to react to a failure. Depends on term.sh's pln/term_cyan/term_red;
# every current caller already sources both.
symlink_setup_reporting() {
  local target="$1" link="$2"
  if [ -n "$SETUP_DRY_RUN" ]; then
    pln "$(term_cyan '[DRY RUN] Would symlink' "$link" '->' "$target")"
    return 0
  fi
  mkdir -p "$(dirname "$link")"
  if ! symlink_setup "$target" "$link"; then
    pln "$(term_red "failed to symlink $link")" >&2
    return 1
  fi
  echo "  $link -> $target"
}
