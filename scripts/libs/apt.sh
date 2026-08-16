#!/usr/bin/env bash
# Parses a plain-text apt package list (see home/Aptfile): one package per
# line, blank lines and #-prefixed comments ignored. Keeps apt package
# declarations data rather than logic, mirroring how Brewfile keeps brew's
# packages declarative.

# apt_packages_from_file file
# Prints one package name per line, with comments and blank lines stripped.
apt_packages_from_file() {
  local file="$1"
  grep -v '^[[:space:]]*#' "$file" | grep -v '^[[:space:]]*$'
}
