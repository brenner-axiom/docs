---
layout: page
title: "Ops Toil Audit"
permalink: /ops/toil-audit
---

# Ops Toil Audit — #B4mad Infrastructure

**Bead:** beads-hub-8e4 | **Date:** 2026-02-20 | **Author:** PltOps

## Current Manual / Repetitive Processes

### 1. Heartbeat Dispatch Loop (HEARTBEAT.md)
- **What:** Every heartbeat polls beads-hub, classifies beads, spawns agents, notifies goern
- **Frequency:** Every ~30 min
- **Toil:** `git pull && bd ready --json` + classification + dispatch + Signal notification
- **Automation opportunity:** **HIGH** — A dedicated cron job or webhook on beads-hub could auto-dispatch beads without burning main-agent tokens. A simple script: `bd ready --json | jq` → match keywords → spawn agent via OpenClaw API.

### 2. Memory File Management
- **What:** Daily `memory/YYYY-MM-DD.md` creation, periodic MEMORY.md curation
- **Frequency:** Every session + periodic review
- **Toil:** Manual file creation, reading old files, distilling into MEMORY.md
- **Automation opportunity:** **MEDIUM** — Auto-create daily file on first heartbeat. Auto-archive files older than 14 days. Memory curation requires judgment (keep manual).

### 3. Bead Sync & Push
- **What:** `bd sync && git push` after every bead operation
- **Frequency:** Multiple times per session
- **Toil:** Repetitive git ceremony
- **Automation opportunity:** **HIGH** — Wrapper script `bd-sync` that does `bd sync && git push` in one command. Or a post-commit hook in beads-hub.

### 4. PR/Issue Follow-Up (open-prs.json)
- **What:** Check each PR status, ping stale ones, spawn CodeMonkey for changes
- **Frequency:** Daily during business hours
- **Toil:** HTTP calls to Codeberg/GitHub APIs, status comparison
- **Automation opportunity:** **HIGH** — GitHub/Codeberg webhooks or a cron script that checks `open-prs.json` entries and posts results to a status file.

### 5. Dispatched Beads Tracking (dispatched-beads.json)
- **What:** Manual JSON updates to track which beads have been dispatched
- **Toil:** Read/write JSON, dedup checks
- **Automation opportunity:** **MEDIUM** — Could use bead status field (`in_progress` + `owner`) instead of a separate tracking file.

### 6. CI/CD & Deployment
- **What:** No formal CI/CD pipelines observed in workspace. Deployments appear manual.
- **Toil:** Unknown frequency, likely ad-hoc
- **Automation opportunity:** **HIGH** — Set up Tekton/GitHub Actions for repos. Add `sync-and-deploy.sh` if not present.

### 7. Cron Jobs
- **Current state:** No crontab entries for the `ubuntu` user
- **Automation opportunity:** OpenClaw cron handles scheduled tasks, but system-level cron is unused — could offload exact-timing tasks there.

## Recommendations (Priority Order)

| # | Action | Impact | Effort |
|---|--------|--------|--------|
| 1 | Create `bd-sync` wrapper script (sync + push) | Eliminates repetitive git ceremony | 5 min |
| 2 | Auto-dispatch script for beads (keyword matcher) | Reduces heartbeat token burn ~50% | 2 hr |
| 3 | PR status checker cron script | Eliminates manual API polling | 1 hr |
| 4 | Auto-create daily memory file on first heartbeat | Removes boilerplate | 10 min |
| 5 | Archive old memory files (>14d) automatically | Reduces context clutter | 30 min |
| 6 | Eliminate `dispatched-beads.json` — use bead owner/status | Removes redundant tracking | 30 min |
| 7 | Set up CI/CD for key repos | Proper deployment pipeline | 4 hr |

## Estimated Toil Reduction

Current estimated toil: ~2-3 hours/day of agent compute on repetitive tasks.
With items 1-5 implemented: ~1 hour/day (50-60% reduction).
