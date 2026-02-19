#!/usr/bin/env bash
# update-fleet-stats.sh — Regenerate fleet dashboard data from beads-hub
# Usage: ./scripts/update-fleet-stats.sh [beads-hub-path]
#
# This script reads bead data and outputs a JSON summary that can be
# used to update fleet/index.html. For now it prints stats to stdout;
# a future version can template the HTML directly.

set -euo pipefail

BEADS_HUB="${1:-$HOME/.openclaw/workspaces/beads-hub}"
DOCS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$BEADS_HUB" ]; then
  echo "ERROR: beads-hub not found at $BEADS_HUB" >&2
  exit 1
fi

cd "$BEADS_HUB"
git pull -q 2>/dev/null || true

echo "{"
echo "  \"generated\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","

# Count beads by status
TOTAL=$(find beads/ -name "*.md" 2>/dev/null | wc -l)
CLOSED=$(grep -rl 'status: closed' beads/ 2>/dev/null | wc -l)
OPEN=$(grep -rl 'status: open' beads/ 2>/dev/null | wc -l)
IN_PROGRESS=$(grep -rl 'status: in_progress' beads/ 2>/dev/null | wc -l)

echo "  \"beads\": {"
echo "    \"total\": $TOTAL,"
echo "    \"closed\": $CLOSED,"
echo "    \"open\": $OPEN,"
echo "    \"in_progress\": $IN_PROGRESS"
echo "  },"

# Count today's closed beads (distance flown today)
TODAY=$(date -u '+%Y-%m-%d')
TODAY_CLOSED=$(grep -rl 'status: closed' beads/ 2>/dev/null | xargs grep -l "$TODAY" 2>/dev/null | wc -l)

echo "  \"today\": {"
echo "    \"date\": \"$TODAY\","
echo "    \"distance_flown_nm\": $TODAY_CLOSED"
echo "  },"

# Recent closed beads as flight log entries
echo "  \"flight_log\": ["
FIRST=true
grep -rl 'status: closed' beads/ 2>/dev/null | head -10 | while read -r f; do
  TITLE=$(grep '^title:' "$f" 2>/dev/null | head -1 | sed 's/^title: *//' | sed 's/"//g')
  ID=$(basename "$f" .md)
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo ","
  fi
  printf '    {"id": "%s", "title": "%s"}' "$ID" "$TITLE"
done
echo ""
echo "  ]"
echo "}"

echo ""
echo "# To update the dashboard, edit fleet/index.html with these values."
echo "# Future: integrate with a templating system for auto-generation."
