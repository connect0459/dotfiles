#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/libs"
  source "$LIB_DIR/term.sh"
}

# bats runs commands with stdout piped (not a tty), so term_enabled is false
# here and every wrapper is expected to pass the string through unchanged.

@test "term_bold passes text through unchanged when stdout is not a tty" {
  run term_bold "hello"
  [ "$output" = "hello" ]
}

@test "term_dim passes text through unchanged when stdout is not a tty" {
  run term_dim "hello"
  [ "$output" = "hello" ]
}

@test "term_red passes text through unchanged when stdout is not a tty" {
  run term_red "hello"
  [ "$output" = "hello" ]
}

@test "term_green passes text through unchanged when stdout is not a tty" {
  run term_green "hello"
  [ "$output" = "hello" ]
}

@test "term_cyan passes text through unchanged when stdout is not a tty" {
  run term_cyan "hello"
  [ "$output" = "hello" ]
}

@test "term_bold_green passes text through unchanged when stdout is not a tty" {
  run term_bold_green "hello"
  [ "$output" = "hello" ]
}

@test "term_wrap adds ANSI codes when forced on" {
  TERM_FORCE_COLOR=1 run term_bold "hello"
  [ "$output" = $'\033[1mhello\033[0m' ]
}

# term_wrap is always invoked as "$(term_xxx ...)", which puts fd 1 on a pipe
# to the capture buffer rather than the real terminal — so a tty check made
# lazily inside term_enabled/term_wrap would always read false, even when the
# script's own stdout is a real terminal. That regression can only be shown
# by actually giving the sourcing shell a real tty on fd 1, so this spawns
# one via script(1) rather than mocking `[ -t 1 ]`.
@test "term_bold emits color when the real terminal is a tty, even though term_wrap runs inside a command substitution" {
  command -v script >/dev/null || skip "script(1) not available in this environment"

  if [ "$(uname -s)" = "Darwin" ]; then
    run script -q /dev/null bash -c "source '$LIB_DIR/term.sh'; printf '%s' \"\$(term_bold hello)\""
  else
    run script -qc "bash -c \"source '$LIB_DIR/term.sh'; printf '%s' \\\"\\\$(term_bold hello)\\\"\"" /dev/null
  fi

  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033[1mhello\033[0m'* ]]
}
