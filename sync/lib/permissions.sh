#!/usr/bin/env bash
# Ported from sync_cmd/permissions.py, extended to avoid data loss when this
# is wired up against a real, live ~/.claude/settings.json (see sync.sh).
#
# Every top-level key in source is merged into target (source wins on
# conflicts, target-only keys are preserved) -- despite the module name, this
# is not a filter limited to the "permissions" key.
#
# permissions.allow/deny/ask are the exception: they are unioned (deduped,
# sorted) rather than replaced outright, so permission entries a user added
# locally -- e.g. via `/permissions add`, never present in source -- survive
# a sync instead of being silently dropped. The tradeoff this accepts: an
# entry that source used to distribute and later removes will keep lingering
# in target, since a plain union can only add, never retract.

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
    ($t[0].permissions) as $tp
    | ($s[0].permissions) as $sp
    | ($t[0] + $s[0]) as $shallow
    | if ($tp == null) and ($sp == null) then
        $shallow
      else
        ($tp // {}) as $tpv
        | ($sp // {}) as $spv
        | $shallow
        | .permissions = (
            ($tpv * $spv)
            | .allow = ((($tpv.allow // []) + ($spv.allow // [])) | unique)
            | .deny  = ((($tpv.deny  // []) + ($spv.deny  // [])) | unique)
            | .ask   = ((($tpv.ask   // []) + ($spv.ask   // [])) | unique)
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
