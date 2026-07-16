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

@test "merge overwrites existing permissions" {
  printf '{"permissions": {"allow": ["new"]}}' > "$TMP/source.json"
  printf '{"permissions": {"allow": ["old"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq -r '.permissions.allow[0]' "$TMP/target.json")" = "new" ]
}

@test "merge preserves non-permissions fields in target" {
  printf '{"permissions": {"allow": []}}' > "$TMP/source.json"
  printf '{"theme": "dark", "permissions": {"allow": ["old"]}}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq -r '.theme' "$TMP/target.json")" = "dark" ]
  [ "$(jq -c '.permissions.allow' "$TMP/target.json")" = "[]" ]
}

@test "merge applies all top-level source fields to target" {
  printf '{"permissions": {"allow": ["read"]}, "enabledPlugins": {"cc-plugin@connect0459": true}, "extraKnownMarketplaces": {"connect0459": {}}}' > "$TMP/source.json"
  printf '{}' > "$TMP/target.json"

  permissions_merge "$TMP/source.json" "$TMP/target.json"

  [ "$(jq 'has("enabledPlugins")' "$TMP/target.json")" = "true" ]
  [ "$(jq 'has("extraKnownMarketplaces")' "$TMP/target.json")" = "true" ]
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
