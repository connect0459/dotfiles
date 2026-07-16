#!/usr/bin/env bats

setup() {
  LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/lib"
  source "$LIB_DIR/permissions.sh"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP"
}

@test "merge applies source permissions to target" {
  printf '{"permissions": {"allow": ["read"]}}' > "$TMP/source.json"
  printf '{}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq -r '.permissions.allow[0]' "$TMP/target.json")" = "read" ]
}

@test "merge creates target when it does not exist" {
  printf '{"permissions": {"allow": ["write"]}}' > "$TMP/source.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq -r '.permissions.allow[0]' "$TMP/target.json")" = "write" ]
}

@test "merge unions new source permissions with existing target permissions" {
  printf '{"permissions": {"allow": ["new"]}}' > "$TMP/source.json"
  printf '{"permissions": {"allow": ["old"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq -c '.permissions.allow' "$TMP/target.json" | tr -d '\n')" = '["new","old"]' ]
}

@test "merge preserves non-permissions fields in target" {
  printf '{"permissions": {"allow": []}}' > "$TMP/source.json"
  printf '{"theme": "dark", "permissions": {"allow": ["old"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq -r '.theme' "$TMP/target.json")" = "dark" ]
  [ "$(jq -c '.permissions.allow' "$TMP/target.json")" = '["old"]' ]
}

@test "merge preserves a target-only permission entry not present in source" {
  printf '{"permissions": {"allow": ["Bash(git status:*)"], "deny": ["Bash(sudo:*)"]}}' > "$TMP/source.json"
  printf '{"permissions": {"allow": ["Bash(git status:*)", "Bash(my-local-tool:*)"], "deny": ["Bash(sudo:*)"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq '.permissions.allow | length' "$TMP/target.json")" = "2" ]
  [ "$(jq 'any(.permissions.allow[]; . == "Bash(my-local-tool:*)")' "$TMP/target.json")" = "true" ]
}

@test "merge deduplicates a permission entry present in both source and target" {
  printf '{"permissions": {"allow": ["Bash(git status:*)"]}}' > "$TMP/source.json"
  printf '{"permissions": {"allow": ["Bash(git status:*)"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq '.permissions.allow | length' "$TMP/target.json")" = "1" ]
}

@test "merge unions the deny list without dropping target-only entries" {
  printf '{"permissions": {"deny": ["Bash(rm -rf:*)"]}}' > "$TMP/source.json"
  printf '{"permissions": {"deny": ["Bash(rm -rf:*)", "Bash(my-local-deny:*)"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq '.permissions.deny | length' "$TMP/target.json")" = "2" ]
}

@test "merge applies all top-level source fields to target" {
  printf '{"permissions": {"allow": ["read"]}, "enabledPlugins": {"cc-plugin@connect0459": true}, "extraKnownMarketplaces": {"connect0459": {}}}' > "$TMP/source.json"
  printf '{}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq 'has("enabledPlugins")' "$TMP/target.json")" = "true" ]
  [ "$(jq 'has("extraKnownMarketplaces")' "$TMP/target.json")" = "true" ]
}

@test "merge preserves a target-only key nested under a shared top-level object" {
  printf '{"enabledPlugins": {"cc-plugin@connect0459": true}}' > "$TMP/source.json"
  printf '{"enabledPlugins": {"cc-plugin@connect0459": true, "my-local-plugin@me": true}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq '.enabledPlugins | has("my-local-plugin@me")' "$TMP/target.json")" = "true" ]
}

@test "merge does not inject empty deny/ask arrays when neither side defines them" {
  printf '{"permissions": {"allow": ["read"]}}' > "$TMP/source.json"
  printf '{}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq '.permissions | has("deny")' "$TMP/target.json")" = "false" ]
  [ "$(jq '.permissions | has("ask")' "$TMP/target.json")" = "false" ]
}

@test "merge does not add permissions when source has none" {
  printf '{"other": "value"}' > "$TMP/source.json"
  printf '{}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq 'has("permissions")' "$TMP/target.json")" = "false" ]
  [ "$(jq -r '.other' "$TMP/target.json")" = "value" ]
}

@test "merge fails and leaves target untouched when source is missing" {
  printf '{"theme": "dark"}' > "$TMP/target.json"

  run permissions_merge "$TMP/does-not-exist.json" "$TMP/target.json"

  [ "$status" -ne 0 ]
  [ "$(jq -r '.theme' "$TMP/target.json")" = "dark" ]
}

@test "merge fails and leaves target untouched when source is invalid JSON" {
  printf 'not json' > "$TMP/source.json"
  printf '{"theme": "dark"}' > "$TMP/target.json"

  run permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$status" -ne 0 ]
  [ "$(jq -r '.theme' "$TMP/target.json")" = "dark" ]
}
