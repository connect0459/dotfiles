#!/usr/bin/env bash
# Parses a plain-text apt package list (see home/Aptfile.txt): one package per
# line, blank lines and #-prefixed comments ignored. Keeps apt package
# declarations data rather than logic, mirroring how Brewfile keeps brew's
# packages declarative.

# apt_packages_from_file file
# Prints one package name per line, with surrounding whitespace trimmed and
# comments/blank lines stripped. Returns non-zero if file doesn't exist or
# isn't readable. Uses awk instead of grep so a file with no packages (only
# comments/blank lines) is a successful, empty result rather than the
# non-zero exit grep returns for no matching lines.
apt_packages_from_file() {
  local file="$1"
  if [ ! -r "$file" ]; then
    echo "apt_packages_from_file: cannot read $file" >&2
    return 1
  fi
  awk '{
    line = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
    if (line == "" || line ~ /^#/) next
    print line
  }' "$file"
}
