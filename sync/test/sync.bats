#!/usr/bin/env bats

setup() {
  SYNC_SH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/sync.sh"
  TMP="$(mktemp -d)"
  export HOME="$TMP/home"
  mkdir -p "$HOME"

  SOURCE="$TMP/coding-agents"
  mkdir -p "$SOURCE/agent-docs/testing" "$SOURCE/dot-claude"
  printf 'agents content' > "$SOURCE/AGENTS.md"
  printf 'doc content' > "$SOURCE/agent-docs/testing/foo.md"
  printf '{"permissions": {"allow": ["read"]}}' > "$SOURCE/dot-claude/settings.json"
  export SYNC_SOURCE_DIR="$SOURCE"
}

teardown() {
  rm -rf "$TMP"
}

@test "sync copies AGENTS.md to central location" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.connect0459/coding-agents/AGENTS.md")" = "agents content" ]
}

@test "sync copies agent-docs directory to central location" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.connect0459/coding-agents/agent-docs/testing/foo.md")" = "doc content" ]
}

@test "sync sets up CLAUDE.md as a symlink to central AGENTS.md" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$HOME/.connect0459/coding-agents/AGENTS.md" ]
}

@test "sync sets up copilot-instructions.md as a symlink to central AGENTS.md" {
  run "$SYNC_SH"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.github/copilot-instructions.md" ]
  [ "$(readlink "$HOME/.github/copilot-instructions.md")" = "$HOME/.connect0459/coding-agents/AGENTS.md" ]
}

@test "sync merges dot-claude/settings.json permissions into ~/.claude/settings.json" {
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

@test "sync skips settings merge when source dot-claude/settings.json does not exist" {
  rm -f "$SOURCE/dot-claude/settings.json"

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

@test "sync fails when source AGENTS.md is missing" {
  rm -f "$SOURCE/AGENTS.md"
  run "$SYNC_SH"
  [ "$status" -ne 0 ]
}

@test "sync fails when source agent-docs directory is missing" {
  rm -rf "$SOURCE/agent-docs"
  run "$SYNC_SH"
  [ "$status" -ne 0 ]
}

@test "sync refuses to replace an existing real directory at ~/.claude/CLAUDE.md" {
  mkdir -p "$HOME/.claude/CLAUDE.md"
  run "$SYNC_SH"
  [ "$status" -ne 0 ]
}
