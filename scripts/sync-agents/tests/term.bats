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
