# Beads Integration — Technical Guide

## Overview

[Beads](https://github.com/steveyegge/beads) is a distributed, git-backed graph issue tracker designed for AI agents. We use it as the coordination layer for #B4mad's multi-agent OpenClaw deployment.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    GitHub (Private)                    │
│                                                        │
│  brenner-axiom/beads-hub     ← Cross-project epics    │
│  brenner-axiom/linkedin-brief ← Project-specific tasks │
│  (future project repos)       ← Each has .beads/       │
└──────────┬───────────────────────────┬────────────────┘
           │ git pull/push             │ git pull/push
           │                           │
┌──────────▼──────────┐   ┌───────────▼──────────────┐
│  Axiom (main)       │   │  LinkedIn Brief Agent     │
│  Model: Opus        │   │  Model: Sonnet            │
│  Role: Orchestrator │   │  Role: Feed summaries     │
│                     │   │                            │
│  Can create/assign  │   │  Checks beads-hub for     │
│  beads to any agent │   │  assigned tasks on start   │
└──────────┬──────────┘   └────────────────────────────┘
           │ spawn
┌──────────▼──────────┐
│  CodeMonkey          │
│  Model: Qwen3-Coder │
│  Role: Code tasks    │
│                      │
│  Claims & works on   │
│  coding beads        │
└──────────────────────┘
```

## Components

### 1. beads-hub Repository
- **URL**: https://github.com/brenner-axiom/beads-hub (private)
- **Purpose**: Cross-cutting epics, coordination tasks, inter-agent messages
- **Location**: `~/.openclaw/workspaces/beads-hub/`
- **Sync**: All agents pull from here at session start

### 2. Per-Project .beads/
- Each project repo (linkedin-brief, workspace, etc.) can have its own `.beads/`
- Project-specific tasks stay local to that repo
- Cross-project dependencies link via bead IDs

### 3. Beads Skill
- **Location**: `skills/beads/SKILL.md`
- Provides instructions for any agent on how to use `bd` CLI
- Available to all agents via skill system

### 4. bd CLI
- Installed system-wide at `~/.local/bin/bd`
- Built with CGO for Dolt database support
- Version: 0.52.0

## Task Lifecycle

```
Created → Open → Claimed (in_progress) → Closed
                    ↓
              Blocked (waiting on dependency)
```

### Creating Tasks (Axiom or any agent)
```bash
cd ~/.openclaw/workspaces/beads-hub
bd create "Implement OAuth for #B4mad portal" -p 1 --assign codemonkey --json
bd sync
```

### Working Tasks (assigned agent)
```bash
cd ~/.openclaw/workspaces/beads-hub
git pull --rebase
bd ready --json                    # See what's available
bd update <id> --claim --json      # Atomic claim
# ... do work ...
bd close <id> --reason "Completed" --json
bd sync
```

### Cross-Agent Handoff
```bash
# Axiom creates epic with sub-tasks for different agents
bd create "Deploy new service" -p 1 --json          # Returns bd-abc
bd create "Write deployment script" -p 1 --parent bd-abc --assign codemonkey --json
bd create "Update monitoring config" -p 2 --parent bd-abc --assign axiom --json
bd dep add bd-abc.2 bd-abc.1  # Monitoring depends on deployment script
bd sync
```

## Integration Points

### Heartbeat Check
Axiom can check beads-hub during heartbeats:
```bash
cd ~/.openclaw/workspaces/beads-hub && git pull -q && bd ready --json
```

### Cron Job (optional)
A cron job can periodically check for stale tasks:
```bash
bd list --status open --json | jq '[.[] | select(.updated_at < "2026-02-10")]'
```

### Sub-Agent Spawning
When spawning a sub-agent, include beads context:
```
Task: Work on bd-abc in beads-hub. Pull the repo, claim the bead, do the work, close it, sync.
```

## Git Workflow

1. **Always pull before working**: `git pull --rebase`
2. **Use `bd sync`** after changes (exports JSONL, commits, pushes)
3. **Hash-based IDs** prevent merge conflicts (e.g., `bd-a1b2`)
4. **JSONL is the portable format** — committed to git for cross-platform sync
5. **Dolt DB is local** — gitignored, rebuilt from JSONL on clone

## Troubleshooting

### "dolt database" errors
Ensure `bd` was built with CGO: `CGO_ENABLED=1 go install github.com/steveyegge/beads/cmd/bd@latest`

### Merge conflicts in JSONL
```bash
git checkout --theirs .beads/issues.jsonl
bd import -i .beads/issues.jsonl
```

### Pre-commit hooks hanging
Use `--no-verify` for manual commits, or ensure `bd` is in PATH.
