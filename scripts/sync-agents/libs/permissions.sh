#!/usr/bin/env bash
# Ported from sync_cmd/permissions.py, extended to avoid data loss when this
# is wired up against a real, live ~/.claude/settings.json (see sync-agents.sh).
#
# Every top-level key in source is merged into target (source wins on
# conflicts, target-only keys are preserved) -- despite the module name, this
# is not a filter limited to the "permissions" key. Nested objects (e.g.
# enabledPlugins, extraKnownMarketplaces) are merged recursively rather than
# replaced outright, so a target-only sub-key a user added locally is never
# silently dropped just because source also defines that same top-level key.
#
# permissions.allow/deny/ask specifically are unioned (deduped, sorted)
# rather than merged as plain objects, since they are arrays: a user's
# locally-added permission entry -- e.g. via `/permissions add`, never
# present in source -- survives a sync instead of being silently dropped.
# The tradeoff this accepts: an entry that source used to distribute and
# later removes will keep lingering in target, since a plain union can only
# add, never retract. An allow/deny/ask key absent from both sides is left
# absent rather than materialized as an empty array.

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

  if ! jq -S --indent 2 -n --slurpfile t "$target_tmp" --slurpfile s "$source_path" '
    ($t[0] * $s[0]) as $merged
    | ($t[0].permissions) as $tp
    | ($s[0].permissions) as $sp
    | if ($tp == null) and ($sp == null) then
        $merged
      else
        ($tp // {}) as $tpv
        | ($sp // {}) as $spv
        | $merged
        | .permissions = (
            .permissions
            | if ($tpv.allow == null) and ($spv.allow == null) then . else
                .allow = ((($tpv.allow // []) + ($spv.allow // [])) | unique)
              end
            | if ($tpv.deny == null) and ($spv.deny == null) then . else
                .deny = ((($tpv.deny // []) + ($spv.deny // [])) | unique)
              end
            | if ($tpv.ask == null) and ($spv.ask == null) then . else
                .ask = ((($tpv.ask // []) + ($spv.ask // [])) | unique)
              end
          )
      end
  ' > "${target_path}.tmp" 2>/dev/null; then
    rm -f "$target_tmp" "${target_path}.tmp"
    echo "permissions_merge: failed to merge JSON" >&2
    return 1
  fi

  mv "${target_path}.tmp" "$target_path"
  rm -f "$target_tmp"
}
