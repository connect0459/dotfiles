#!/usr/bin/env bash
# Ported from sync_cmd/term.py.
# TERM_FORCE_COLOR=1 overrides the tty check so wrapping can be exercised
# from a non-interactive test runner.

# term_wrap is normally invoked as "$(term_xxx ...)"; inside that command
# substitution fd 1 is a pipe to the capture buffer, not the real terminal,
# so `[ -t 1 ]` would read false there even in an interactive session. Cache
# the check once, here at source time in the real shell, before any
# subshell/command substitution can shadow fd 1.
if [ -t 1 ]; then
  _TERM_TTY=1
else
  _TERM_TTY=0
fi

term_enabled() {
  [ -n "$TERM_FORCE_COLOR" ] || [ "$_TERM_TTY" = 1 ]
}

term_wrap() {
  local code="$1" s="$2"
  if term_enabled; then
    printf '\033[%sm%s\033[0m' "$code" "$s"
  else
    printf '%s' "$s"
  fi
}

term_bold()       { term_wrap "1" "$1"; }
term_dim()        { term_wrap "2" "$1"; }
term_red()        { term_wrap "31" "$1"; }
term_green()      { term_wrap "32" "$1"; }
term_cyan()       { term_wrap "36" "$1"; }
term_bold_green() { term_wrap "1;32" "$1"; }

pln() {
  printf '%s\n' "$1"
}
