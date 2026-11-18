#!/usr/bin/env bash

profile_list() {
  local profiles_dir="$1" dir
  for dir in "$profiles_dir"/*/; do
    [ -d "$dir" ] || continue
    [ "$(basename "$dir")" = "common" ] && continue
    basename "$dir"
  done
}

profile_resolve() {
  local profiles_dir="$1" state_file="$2" requested="$3" name

  name="$requested"
  if [ -z "$name" ] && [ -r "$state_file" ]; then
    name="$(cat "$state_file")"
  fi

  if [ -z "$name" ]; then
    echo "No profile selected. Pass --profile <name>; available profiles: $(profile_list "$profiles_dir" | tr '\n' ' ')" >&2
    return 1
  fi

  if ! profile_list "$profiles_dir" | grep -qxF -- "$name"; then
    echo "Unknown profile: $name. Available profiles: $(profile_list "$profiles_dir" | tr '\n' ' ')" >&2
    return 1
  fi

  printf '%s\n' "$name"
}

profile_record() {
  local state_file="$1" name="$2"
  mkdir -p "$(dirname "$state_file")"
  printf '%s\n' "$name" > "$state_file"
}
