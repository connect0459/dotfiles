#!/usr/bin/env bash
# Reclaims space from colima's raw disk image, which is sparse but grows
# monotonically: deleting files inside the VM does not shrink it on the
# host without an explicit fstrim.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../libs/term.sh"

usage() {
  cat <<'EOF'
Usage: colima-cleanup.sh [--profile NAME]

Reclaims disk space from a colima VM by running `docker system prune -a -f`
followed by `sudo fstrim -av` inside it.

Options:
  -p, --profile NAME  colima profile to clean up (default: "default")
  -h, --help          show this help

Environment:
  SETUP_DRY_RUN=1  print the commands that would run without executing them
EOF
}

PROFILE="default"

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--profile)
      PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      pln "$(term_red 'Unknown argument:' "$1")" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v colima &> /dev/null; then
  pln "$(term_red 'colima not found. Install it first (see home/Brewfile).')" >&2
  exit 1
fi

if [ -n "${SETUP_DRY_RUN:-}" ]; then
  pln "$(term_cyan "[DRY RUN] Would run: colima ssh --profile $PROFILE -- docker system prune -a -f")"
  pln "$(term_cyan "[DRY RUN] Would run: colima ssh --profile $PROFILE -- sudo fstrim -av")"
  exit 0
fi

if ! colima status --profile "$PROFILE" &> /dev/null; then
  pln "$(term_red "colima profile '$PROFILE' is not running. Start it with: colima start --profile $PROFILE")" >&2
  exit 1
fi

COLIMA_HOME="${COLIMA_HOME:-$HOME/.colima}"

pln "$(term_bold "Cleaning up colima profile '$PROFILE'")"
pln "$(term_dim 'Before:')"
du -sh "$COLIMA_HOME" 2>/dev/null || true
df -h / 2>/dev/null || true

colima ssh --profile "$PROFILE" -- docker system prune -a -f
colima ssh --profile "$PROFILE" -- sudo fstrim -av

echo
pln "$(term_dim 'After:')"
du -sh "$COLIMA_HOME" 2>/dev/null || true
df -h / 2>/dev/null || true
