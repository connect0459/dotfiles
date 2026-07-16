#!/usr/bin/env bash
# Ported from sync_cmd/permissions.py.
#
# Despite the module name, this performs a shallow top-level merge of every
# key in source into target (source wins on conflicts, target-only keys are
# preserved) -- not a filter limited to the "permissions" key. This matches
# the behavior asserted by the original test_permissions.py, which the
# source repo's README describes inaccurately.

permissions_merge() {
  local source_path="$1" target_path="$2"
  local target_tmp

  if [ ! -f "$source_path" ] || ! jq empty "$source_path" >/dev/null 2>&1; then
    echo "permissions_merge: invalid or missing source JSON: $source_path" >&2
    return 1
  fi

  target_tmp="$(mktemp)"
  if [ -f "$target_path" ] && jq empty "$target_path" >/dev/null 2>&1; then
    cp "$target_path" "$target_tmp"
  else
    printf '{}' > "$target_tmp"
  fi

  if ! jq -S --indent 2 -n --slurpfile t "$target_tmp" --slurpfile s "$source_path" \
    '$t[0] + $s[0]' > "${target_path}.tmp" 2>/dev/null; then
    rm -f "$target_tmp" "${target_path}.tmp"
    echo "permissions_merge: failed to merge JSON" >&2
    return 1
  fi

  mv "${target_path}.tmp" "$target_path"
  rm -f "$target_tmp"
}
