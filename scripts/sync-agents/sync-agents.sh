#!/usr/bin/env bash
# Ported from sync_cmd/main.py: wires the libs/*.sh functions together into the
# real sync against $HOME. SYNC_SOURCE_DIR overrides the source home
# directory (used by scripts/sync-agents/tests/sync-agents.bats so tests
# never touch the real $HOME or read from the real source).

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/libs"
source "$LIB_DIR/checksum.sh"
source "$LIB_DIR/dirsync.sh"
source "$LIB_DIR/permissions.sh"
source "$LIB_DIR/symlink.sh"
source "$LIB_DIR/term.sh"

_repeat() {
  local char="$1" count="$2" out=""
  while [ "$count" -gt 0 ]; do
    out="$out$char"
    count=$((count - 1))
  done
  printf '%s' "$out"
}

# printf's own '%-*s' field-width padding counts bytes, not characters, so it
# under-pads multi-byte UTF-8 strings (e.g. "✓") even though bash's ${#s} counts
# characters correctly. Pad manually with ${#s} instead of relying on printf.
_pad_right() {
  local s="$1" width="$2" pad
  pad=$((width - ${#s}))
  [ "$pad" -lt 0 ] && pad=0
  printf '%s%s' "$s" "$(_repeat ' ' "$pad")"
}

SOURCE_DIR="${SYNC_SOURCE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)/home}"
CENTRAL_DIR="$HOME/.agents"
CLAUDE_DIR="$HOME/.claude"
GITHUB_DIR="$HOME/.github"

SOURCE_AGENTS_MD="$SOURCE_DIR/dot_agents/AGENTS.md"
SOURCE_AGENT_DOCS="$SOURCE_DIR/dot_agents/agent-docs"
SOURCE_SETTINGS="$SOURCE_DIR/dot_claude/settings.json"

CENTRAL_AGENTS_MD="$CENTRAL_DIR/AGENTS.md"
CENTRAL_AGENT_DOCS="$CENTRAL_DIR/agent-docs"

CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
COPILOT_INSTRUCTIONS="$GITHUB_DIR/copilot-instructions.md"

pln "$(term_bold 'Coding agents configuration sync tool')"
pln "$(term_dim 'Source:')  $SOURCE_DIR"
pln "$(term_dim 'Central:') $CENTRAL_DIR"
pln "$(term_dim 'Claude:')  $CLAUDE_DIR"
echo

before_agents_md="$(checksum_of "$CENTRAL_AGENTS_MD")"
before_agent_docs="$(checksum_of "$CENTRAL_AGENT_DOCS")"
before_settings="$(checksum_of "$CLAUDE_SETTINGS")"

mkdir -p "$CENTRAL_AGENT_DOCS" "$CLAUDE_DIR" "$GITHUB_DIR"

pln "$(term_cyan 'Syncing AGENTS.md to central location')"
if ! dirsync_copy_file "$SOURCE_AGENTS_MD" "$CENTRAL_AGENTS_MD"; then
  pln "$(term_red "failed to copy AGENTS.md")" >&2
  exit 1
fi

pln "$(term_cyan 'Syncing agent-docs directory to central location')"
if ! dirsync_sync "$SOURCE_AGENT_DOCS" "$CENTRAL_AGENT_DOCS"; then
  pln "$(term_red "failed to sync agent-docs")" >&2
  exit 1
fi

settings_exists=0
if [ -f "$SOURCE_SETTINGS" ]; then
  settings_exists=1
  pln "$(term_cyan 'Syncing settings from settings.json')"
  if ! permissions_merge "$SOURCE_SETTINGS" "$CLAUDE_SETTINGS"; then
    pln "$(term_red "failed to merge settings")" >&2
    exit 1
  fi
fi

echo
pln "$(term_cyan 'Setting up symlinks...')"
if ! symlink_setup "$CENTRAL_AGENTS_MD" "$CLAUDE_MD"; then
  pln "$(term_red "failed to setup symlink for CLAUDE.md")" >&2
  exit 1
fi
echo "  $CLAUDE_MD -> $CENTRAL_AGENTS_MD"

if ! symlink_setup "$CENTRAL_AGENTS_MD" "$COPILOT_INSTRUCTIONS"; then
  pln "$(term_red "failed to setup symlink for copilot-instructions.md")" >&2
  exit 1
fi
echo "  $COPILOT_INSTRUCTIONS -> $CENTRAL_AGENTS_MD"
echo

after_agents_md="$(checksum_of "$CENTRAL_AGENTS_MD")"
after_agent_docs="$(checksum_of "$CENTRAL_AGENT_DOCS")"
after_settings="$(checksum_of "$CLAUDE_SETTINGS")"

separator="$(term_dim "$(_repeat '━' 38)")"
pln "$separator"
pln "$(term_bold 'Change Detection Report')"
pln "$separator"

row_status=()
row_type=()
row_name=()
row_changed=()
has_changes=0

_add_row() {
  local key_before="$1" key_after="$2" item_type="$3" name="$4"
  if [ "$key_before" != "$key_after" ]; then
    row_status+=("✓")
    row_changed+=(1)
    has_changes=1
  else
    row_status+=("-")
    row_changed+=(0)
  fi
  row_type+=("$item_type")
  row_name+=("$name")
}

_add_row "$before_agents_md" "$after_agents_md" "docs" "AGENTS.md"
_add_row "$before_agent_docs" "$after_agent_docs" "docs" "agent-docs/"
if [ "$settings_exists" -eq 1 ]; then
  _add_row "$before_settings" "$after_settings" "docs" "settings.json"
fi

if [ -L "$CLAUDE_MD" ]; then
  row_status+=("✓"); row_type+=("symlink"); row_name+=("Claude"); row_changed+=(1)
  has_changes=1
fi
if [ -L "$COPILOT_INSTRUCTIONS" ]; then
  row_status+=("✓"); row_type+=("symlink"); row_name+=("GitHub Copilot"); row_changed+=(1)
  has_changes=1
fi

header_status="Status"
header_type="Type"
header_name="Name"
w0=${#header_status}
w1=${#header_type}
w2=${#header_name}
i=0
while [ "$i" -lt "${#row_status[@]}" ]; do
  [ "${#row_status[$i]}" -gt "$w0" ] && w0="${#row_status[$i]}"
  [ "${#row_type[$i]}" -gt "$w1" ] && w1="${#row_type[$i]}"
  [ "${#row_name[$i]}" -gt "$w2" ] && w2="${#row_name[$i]}"
  i=$((i + 1))
done

_sep_line() {
  local left="$1" mid="$2" right="$3"
  printf '%s%s%s%s%s%s%s\n' \
    "$left" "$(_repeat '─' $((w0 + 2)))" \
    "$mid" "$(_repeat '─' $((w1 + 2)))" \
    "$mid" "$(_repeat '─' $((w2 + 2)))" \
    "$right"
}

pln "$(term_dim "$(_sep_line '┌' '┬' '┐')")"
printf '│ %s │ %s │ %s │\n' "$(_pad_right "Status" "$w0")" "$(_pad_right "Type" "$w1")" "$(_pad_right "Name" "$w2")"
pln "$(term_dim "$(_sep_line '├' '┼' '┤')")"

i=0
while [ "$i" -lt "${#row_status[@]}" ]; do
  line="$(printf '│ %s │ %s │ %s │' "$(_pad_right "${row_status[$i]}" "$w0")" "$(_pad_right "${row_type[$i]}" "$w1")" "$(_pad_right "${row_name[$i]}" "$w2")")"
  if [ "${row_changed[$i]}" -eq 1 ]; then
    pln "$(term_green "$line")"
  else
    pln "$(term_dim "$line")"
  fi
  i=$((i + 1))
done
pln "$(term_dim "$(_sep_line '└' '┴' '┘')")"

if [ "$has_changes" -eq 1 ]; then
  pln "$(term_bold_green '✓ Changes were applied successfully')"
else
  pln "$(term_bold_green '✓ All files were already up to date')"
fi
