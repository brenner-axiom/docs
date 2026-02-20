#!/usr/bin/env bash
# update-fleet-stats.sh — Update fleet dashboard from beads-hub data
# Idempotent, safe to run every 5 minutes via cron.
# Requires: bd CLI at ~/.local/bin/bd, python3, git
set -euo pipefail

BD="${HOME}/.local/bin/bd"
BEADS_HUB="${HOME}/.openclaw/workspaces/beads-hub"
DOCS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLEET_HTML="${DOCS_DIR}/fleet/index.html"

if [ ! -f "$BD" ]; then echo "ERROR: bd CLI not found at $BD" >&2; exit 1; fi
if [ ! -f "$FLEET_HTML" ]; then echo "ERROR: fleet/index.html not found" >&2; exit 1; fi

# Pull latest data
cd "$BEADS_HUB" && git pull -q 2>/dev/null || true
cd "$DOCS_DIR" && git pull -q 2>/dev/null || true

# Generate updated HTML via Python (reads bd JSON, patches index.html)
python3 << 'PYEOF'
import json, subprocess, sys, re
from datetime import datetime, timezone, timedelta

BD = sys.path  # unused, just use the env
bd = "${HOME}/.local/bin/bd".replace("${HOME}", __import__("os").environ["HOME"])
beads_hub = "${HOME}/.openclaw/workspaces/beads-hub".replace("${HOME}", __import__("os").environ["HOME"])
fleet_html = "${DOCS_DIR}/fleet/index.html".replace("${DOCS_DIR}", __import__("os").environ.get("DOCS_DIR", ""))

import os
bd = os.path.expanduser("~/.local/bin/bd")
beads_hub = os.path.expanduser("~/.openclaw/workspaces/beads-hub")
docs_dir = os.path.dirname(os.path.dirname(os.path.abspath("${0}")))
# Re-derive docs_dir properly
script_dir = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else None
# Just use env
fleet_html = os.environ.get("FLEET_HTML", "")
if not fleet_html:
    # Fallback
    fleet_html = os.path.expanduser("~/.openclaw/workspaces/docs/fleet/index.html")

def bd_list(status=None):
    cmd = [bd, "list", "--json"]
    if status:
        cmd += ["--status", status]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=beads_hub)
    if r.returncode != 0:
        print(f"bd error: {r.stderr}", file=sys.stderr)
        return []
    return json.loads(r.stdout)

now = datetime.now(timezone.utc)
cutoff = now - timedelta(hours=24)

all_beads = bd_list()
closed_beads = bd_list("closed")
open_beads = [b for b in all_beads if b["status"] == "open"]
in_progress = [b for b in all_beads if b["status"] == "in_progress"]

# Recent closed (last 24h)
recent_closed = [b for b in closed_beads if b.get("closed_at") and b["closed_at"] > cutoff.isoformat()]
recent_closed.sort(key=lambda b: b.get("closed_at", ""), reverse=True)

# All-time counts
total_closed = len(closed_beads)
total_open = len(open_beads)
total_in_progress = len(in_progress)
total_all = total_closed + total_open + total_in_progress

# Stats mapping (aviation metaphors)
distance_nm = total_closed  # each closed bead = 1 nautical mile
sorties = total_all  # total beads = total sorties
fleet_ready = f"{min(5, 5)}/6"  # could be dynamic later

# Agent mapping for flight log
def guess_agent(title):
    t = title.lower()
    if "research:" in t: return "ROMANOV"
    if "container" in t or "ci/cd" in t or "deploy" in t or "fix" in t or "github" in t or "pipeline" in t: return "PLTOPS"
    if "code" in t or "script" in t or "build" in t or "dao" in t or "smart contract" in t: return "CODEMONKEY"
    if "url" in t or "brew" in t or "summar" in t: return "BREW"
    if "linkedin" in t: return "LINKEDIN BRIEF"
    return "TOWER"

# Build flight log HTML (last 10 recent closed)
log_entries = []
for b in recent_closed[:10]:
    closed_at = b.get("closed_at", "")
    try:
        t = datetime.fromisoformat(closed_at.replace("Z", "+00:00"))
        time_str = t.strftime("%H:%MZ")
    except:
        time_str = "??:??Z"
    agent = guess_agent(b["title"])
    bead_id = b["id"]
    # Truncate title
    title = b["title"][:60]
    log_entries.append(
        f'  <div class="log-entry">\n'
        f'    <span class="log-time">{time_str}</span>\n'
        f'    <span class="log-callsign">{agent}</span>\n'
        f'    <span class="log-mission">{title} — {bead_id}</span>\n'
        f'    <span class="log-status"><span class="complete">✓ RTB</span></span>\n'
        f'  </div>'
    )

# If no recent closed, also show in_progress as ACTIVE
for b in in_progress[:max(0, 10 - len(log_entries))]:
    agent = guess_agent(b["title"])
    title = b["title"][:60]
    updated = b.get("updated_at", "")
    try:
        t = datetime.fromisoformat(updated.replace("Z", "+00:00"))
        time_str = t.strftime("%H:%MZ")
    except:
        time_str = "??:??Z"
    log_entries.append(
        f'  <div class="log-entry">\n'
        f'    <span class="log-time">{time_str}</span>\n'
        f'    <span class="log-callsign">{agent}</span>\n'
        f'    <span class="log-mission">{title} — {b["id"]}</span>\n'
        f'    <span class="log-status"><span class="active">● ACTIVE</span></span>\n'
        f'  </div>'
    )

flight_log_html = "\n".join(log_entries)

# Read HTML
with open(fleet_html, "r") as f:
    html = f.read()

# Update timestamp in status line
now_str = now.strftime("%d %b %Y").upper()
html = re.sub(
    r'ALL SYSTEMS NOMINAL — LAST 24H OPS SUMMARY — [^<]+',
    f'ALL SYSTEMS NOMINAL — LAST 24H OPS SUMMARY — {now_str}',
    html
)

# Update footer timestamp
now_full = now.strftime("%d %b %Y %H:%MZ").upper()
html = re.sub(
    r'UPDATED: [^·]+·',
    f'UPDATED: {now_full} · ',
    html
)

# Update stats bar values (order: distance, fuel, passengers, flight hrs, sorties, fleet ready)
stat_values = [
    str(distance_nm),           # Distance Flown (nm)
    f"{total_all * 35:.1f}K",   # Fuel Burned (rough token estimate)
    str(total_open + total_in_progress),  # Passengers (active beads)
    f"{total_all * 0.6:.1f}",   # Flight Hours
    str(sorties),               # Sorties Flown
    fleet_ready,                # Fleet Ready
]

# Replace stat values by finding stat-value divs followed by stat-unit/stat-label
# We'll do targeted replacements based on stat-label text
label_value_map = {
    "Distance Flown": str(distance_nm),
    "Fuel Burned": f"{total_all * 35:.0f}K",
    "Passengers": str(total_open + total_in_progress),
    "Flight Hours": f"{total_all * 0.6:.1f}",
    "Sorties Flown": str(sorties),
    "Fleet Ready": fleet_ready,
}

for label, value in label_value_map.items():
    # Match the stat-item block containing this label and update its value
    pattern = re.compile(
        r'(<div class="stat-value">)[^<]*(</div>\s*<div class="stat-unit">[^<]*</div>\s*<div class="stat-label">' + re.escape(label) + r'</div>)',
        re.DOTALL
    )
    html = pattern.sub(rf'\g<1>{value}\2', html)

# Replace flight log section
flight_log_pattern = re.compile(
    r'(<div class="flight-log">\n)(.*?)(</div>\s*\n\s*<div style="text-align: center)',
    re.DOTALL
)
html = flight_log_pattern.sub(
    rf'\g<1>{flight_log_html}\n\3',
    html
)

with open(fleet_html, "w") as f:
    f.write(html)

print(f"Updated fleet dashboard: {total_closed} closed, {total_open} open, {total_in_progress} in_progress, {len(recent_closed)} recent closed (24h)")
PYEOF

# Commit and push if changed
cd "$DOCS_DIR"
if git diff --quiet fleet/index.html 2>/dev/null; then
  echo "No changes to fleet dashboard."
else
  git add fleet/index.html
  git commit -m "fleet: auto-update dashboard stats $(date -u '+%Y-%m-%dT%H:%MZ')"
  git push
  echo "Fleet dashboard updated and pushed."
fi
