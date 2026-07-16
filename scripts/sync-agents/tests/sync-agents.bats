#!/usr/bin/env bats

setup() {
  SYNC_SH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/sync-agents.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  mkdir -p "$HOME"

  SOURCE="$TMP/source-home"
  mkdir -p "$SOURCE/dot_agents/agent-docs/testing" "$SOURCE/dot_claude"
  printf 'agents content' > "$SOURCE/dot_agents/AGENTS.md"
  printf 'doc content' > "$SOURCE/dot_agents/agent-docs/testing/foo.md"
  printf '{"permissions": {"allow": ["read"]}}' > "$SOURCE/dot_claude/settings.json"
  export SYNC_SOURCE_DIR="$SOURCE"
}

teardown() {
  rm -rf "$TMP"
}

@test "sync copies AGENTS.md to central location" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.agents/AGENTS.md")" = "agents content" ]
}

@test "sync copies agent-docs directory to central location" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.agents/agent-docs/testing/foo.md")" = "doc content" ]
}

@test "sync sets up CLAUDE.md as a symlink to central AGENTS.md" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$HOME/.agents/AGENTS.md" ]
}

@test "sync sets up copilot-instructions.md as a symlink to central AGENTS.md" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.github/copilot-instructions.md" ]
  [ "$(readlink "$HOME/.github/copilot-instructions.md")" = "$HOME/.agents/AGENTS.md" ]
}

@test "sync merges dot_claude/settings.json permissions into ~/.claude/settings.json" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.permissions.allow[0]' "$HOME/.claude/settings.json")" = "read" ]
}

@test "sync preserves existing unrelated keys in ~/.claude/settings.json" {
  mkdir -p "$HOME/.claude"
  printf '{"theme": "dark"}' > "$HOME/.claude/settings.json"

  run "$SYNC_SH"

  [ "$status" -eq 0 ]
  [ "$(jq -r '.theme' "$HOME/.claude/settings.json")" = "dark" ]
}

@test "sync skips settings merge when source dot_claude/settings.json does not exist" {
  rm -f "$SOURCE/dot_claude/settings.json"

  run "$SYNC_SH"

  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/settings.json" ]
}

@test "sync reports docs as unchanged on a second run with no source changes" {
  "$SYNC_SH" >/dev/null

  run "$SYNC_SH"

  [ "$status" -eq 0 ]
  [[ "$output" == *"- "*"docs"*"AGENTS.md"* ]]
}

@test "sync reports changes on first run" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Changes were applied successfully"* ]]
}

@test "sync aligns Change Detection Report borders across changed (✓) and unchanged (-) rows" {
  "$SYNC_SH" >/dev/null

  # Second run: docs rows are unchanged ("-"), symlink rows still report as
  # changed ("✓"), giving a report with both row kinds to compare.
  run "$SYNC_SH"
  [ "$status" -eq 0 ]

  local top_border header_row changed_row unchanged_row bottom_border
  top_border="$(printf '%s\n' "$output" | grep '^┌')"
  header_row="$(printf '%s\n' "$output" | grep '^│ Status')"
  changed_row="$(printf '%s\n' "$output" | grep '^│ ✓' | head -n 1)"
  unchanged_row="$(printf '%s\n' "$output" | grep '^│ -' | head -n 1)"
  bottom_border="$(printf '%s\n' "$output" | grep '^└')"

  [ -n "$top_border" ]
  [ -n "$header_row" ]
  [ -n "$changed_row" ]
  [ -n "$unchanged_row" ]
  [ -n "$bottom_border" ]

  # printf '%-*s' pads by byte count, not character count, so a row
  # containing the multi-byte "✓" used to come out narrower than the header
  # and border lines. ${#line} counts characters correctly here, so equal
  # lengths mean the box-drawing borders actually line up.
  [ "${#changed_row}" -eq "${#header_row}" ]
  [ "${#unchanged_row}" -eq "${#header_row}" ]
  [ "${#top_border}" -eq "${#header_row}" ]
  [ "${#bottom_border}" -eq "${#header_row}" ]
}

@test "sync fails when source AGENTS.md is missing" {
  rm -f "$SOURCE/dot_agents/AGENTS.md"
  run "$SYNC_SH"
  [ "$status" -ne 0 ]
}

@test "sync fails when source agent-docs directory is missing" {
  rm -rf "$SOURCE/dot_agents/agent-docs"
  run "$SYNC_SH"
  [ "$status" -ne 0 ]
}

@test "sync refuses to replace an existing real directory at ~/.claude/CLAUDE.md" {
  mkdir -p "$HOME/.claude/CLAUDE.md"
  run "$SYNC_SH"
  [ "$status" -ne 0 ]
}
