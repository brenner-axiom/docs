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

# --- 24-hour rolling window ---
CUTOFF=$(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -u -v-24H '+%Y-%m-%dT%H:%M:%S')
NOW_UTC=$(date -u '+%d %b %Y %H:%MZ' | tr '[:lower:]' '[:upper:]')

# Collect bead files modified in the last 24 hours
RECENT_BEADS=$(find beads/ -name "*.md" -newermt "$CUTOFF" 2>/dev/null || find beads/ -name "*.md" -mtime -1 2>/dev/null)

echo "{"
echo "  \"generated\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
echo "  \"window\": \"last_24h\","
echo "  \"cutoff\": \"$CUTOFF\","

# Count beads by status (last 24h only)
TOTAL=$(echo "$RECENT_BEADS" | grep -c . || echo 0)
CLOSED=$(echo "$RECENT_BEADS" | xargs grep -l 'status: closed' 2>/dev/null | wc -l)
OPEN=$(echo "$RECENT_BEADS" | xargs grep -l 'status: open' 2>/dev/null | wc -l)
IN_PROGRESS=$(echo "$RECENT_BEADS" | xargs grep -l 'status: in_progress' 2>/dev/null | wc -l)

echo "  \"beads_24h\": {"
echo "    \"total\": $TOTAL,"
echo "    \"closed\": $CLOSED,"
echo "    \"open\": $OPEN,"
echo "    \"in_progress\": $IN_PROGRESS"
echo "  },"

# Distance flown = closed beads in window
echo "  \"window_stats\": {"
echo "    \"distance_flown_nm\": $CLOSED,"
echo "    \"updated\": \"$NOW_UTC\""
echo "  },"

# Recent closed beads as flight log entries (last 24h only)
echo "  \"flight_log\": ["
FIRST=true
echo "$RECENT_BEADS" | xargs grep -l 'status: closed' 2>/dev/null | head -10 | while read -r f; do
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
