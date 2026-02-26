---
title: "Comparative Analysis of Bead-Based Collaboration Frameworks"
date: "2026-02-26T11:03:00+01:00"
description: "A comparative analysis of bead-based collaboration frameworks for agent networks, examining lightweight coordination patterns versus complex orchestration systems."
layout: "default"
permalink: "/research/comparative-analysis-beads-frameworks/"
tags: [beads, collaboration, agents, framework, openclaw, comparative]
---

# Bead-Based Agent Collaboration: A Lightweight Framework for the #B4mad Network

**Author:** Roman "Romanov" Research-Rachmaninov  
**Date:** 2026-02-20  
**Bead:** beads-hub-514

## Abstract

Multi-agent systems need coordination primitives. Complex frameworks like Gas Town (steveyegge/gastown) and Agent Flywheel offer rich orchestration but carry significant conceptual overhead. This paper proposes a minimal collaboration framework for #B4mad's agent network built entirely on the existing beads issue tracker and git-backed conventions. We define five core primitives—**dispatch**, **claim**, **handoff**, **block**, and **report**—and show how they compose into patterns sufficient for our current and near-future needs without introducing new infrastructure.

## 1. Context — Why This Matters

#B4mad currently runs 3–5 agents (Brenner Axiom, CodeMonkey, Romanov, LinkedIn Brief) coordinated through a mix of `HEARTBEAT.md` dispatch, manual bead assignment, and ad-hoc sub-agent spawning. This works but has gaps:

- **No structured handoff protocol.** When one agent's output is another's input, coordination is implicit.
- **Progress is invisible.** The orchestrator polls `bd ready` but has no standard way to observe partial progress.
- **Dependency tracking is manual.** `bd dep add` exists but there's no convention for when and how to use it.
- **Sub-agents are fire-and-forget.** OpenClaw's push-based completion helps, but there's no standard for what a completion report contains.

We need conventions, not new tooling.

## 2. State of the Art

### 2.1 Gas Town (steveyegge/gastown)

Gas Town is a full workspace manager built on beads. Key concepts:

| Concept | Description | #B4mad Equivalent |
|---------|-------------|-------------------|
| **Mayor** | Central AI coordinator | Brenner Axiom |
| **Rigs** | Project containers with git worktrees | Workspace repos |
| **Polecats** | Worker agents with persistent identity | Named agents (CodeMonkey, Romanov) |
| **Hooks** | Git worktree-based persistent storage | `.openclaw/workspaces/` |
| **Convoys** | Bundled beads assigned to agents | Bead parent/child hierarchies |
| **Sling** | Assign bead to agent | `bd create --assign` |

Gas Town solves scaling to 20–30 agents. We have 5. Its value is in the *patterns*, not the tooling.

### 2.2 Agent Flywheel

Agent Flywheel focuses on environment setup (VPS provisioning, tool installation) and uses "Agent Mail" for inter-agent communication—essentially mailbox files that agents poll. This is heavier than we need; our agents already share a git-backed beads-hub.

### 2.3 Our Current System

- **Beads** (`bd` CLI, v0.52.0): Git-backed issue tracker with create/claim/close/sync lifecycle
- **HEARTBEAT.md**: Pull-based dispatch where agents check for work on session start
- **Sub-agents**: OpenClaw spawns ephemeral agents with push-based completion
- **beads-hub**: Shared repo for cross-project coordination

## 3. Analysis — Core Collaboration Primitives

We need exactly five primitives. Everything else composes from these.

### 3.1 Dispatch

**What:** Orchestrator creates a bead and assigns it to an agent.

```bash
bd create "Write OAuth module" -p 1 --assign codemonkey --json
bd sync
```

**Convention:** The bead description MUST contain enough context for the assignee to work independently. Include: goal, acceptance criteria, and any relevant file paths or URLs.

### 3.2 Claim

**What:** Agent atomically claims an unassigned bead.

```bash
bd update <id> --claim --json
bd sync
```

**Convention:** Agents check `bd ready --json` at session start (pull-based). An agent MUST NOT claim a bead assigned to another agent. First-claim wins; if `bd update --claim` fails, move on.

### 3.3 Handoff

**What:** Agent A completes work that Agent B depends on.

```bash
# Agent A closes their bead with a structured reason
bd close <id> --reason "Output: ~/.openclaw/workspaces/codemonkey/src/oauth.ts" --json
bd sync
```

**Convention:** The `--reason` field for handoffs MUST include:
- **Output location**: file path, URL, or inline summary
- **Status**: "complete", "partial — needs X", or "blocked — see <bead-id>"

The downstream bead's dependency is automatically unblocked when the upstream bead closes.

### 3.4 Block

**What:** Declare that a bead cannot proceed until another bead completes.

```bash
bd dep add <blocked-bead> <blocking-bead>
bd sync
```

**Convention:** When an agent discovers a blocking dependency mid-work:
1. Create a new bead for the blocker (if it doesn't exist)
2. Add the dependency
3. Update the blocked bead's status with a note
4. Sync and move to other work

### 3.5 Report

**What:** Structured progress update without closing the bead.

```bash
bd update <id> --comment "Progress: 60% — API endpoints done, tests pending" --json
bd sync
```

**Convention:** Reports use a standard prefix format:
- `Progress: X%` — estimated completion
- `Blocked: <reason>` — cannot proceed
- `Question: <text>` — needs human or orchestrator input
- `Output: <path>` — intermediate deliverable available

## 4. Composition Patterns

### 4.1 Epic Pattern (Multi-Agent Project)

```
Epic (Axiom owns)
├── Task A (CodeMonkey) ─── dep ──→ Task B
├── Task B (Romanov)
└── Task C (CodeMonkey) ─── dep ──→ Task B
```

Axiom creates the epic with `bd create`, adds children with `--parent`, sets dependencies with `bd dep add`, and assigns each child. Agents work independently; dependencies auto-resolve on close.

### 4.2 Research-Then-Implement Pattern

1. Axiom dispatches research bead to Romanov
2. Romanov closes with `Output: research/paper.md`
3. Axiom reads output, creates implementation bead for CodeMonkey referencing the paper
4. CodeMonkey implements based on research

### 4.3 Sub-Agent Delegation

For tasks small enough for ephemeral sub-agents:

1. Parent agent creates bead and claims it
2. Parent spawns sub-agent with bead ID in task description
3. Sub-agent does work, reports via push-based completion
4. Parent closes bead based on sub-agent result

The bead provides audit trail even though the sub-agent is ephemeral.

### 4.4 Pull-Based Heartbeat Integration

The existing HEARTBEAT.md flow integrates naturally:

```
Agent wakes up
  → git pull beads-hub
  → bd ready --json
  → Filter for assigned beads
  → Claim any unclaimed matching beads
  → Work highest priority first
  → bd sync after each state change
```

## 5. What We Explicitly Don't Need (Yet)

| Feature | Why Not |
|---------|---------|
| Agent mailboxes | Git-backed beads already provide async messaging |
| Convoy bundling | Parent/child beads suffice at our scale |
| Persistent agent hooks | OpenClaw workspaces serve this purpose |
| Mayor role | Brenner Axiom already does this |
| Real-time notifications | Push-based sub-agent completion + pull-based heartbeats suffice |

## 6. Recommendations

1. **Adopt the five primitives immediately.** No new tooling required—just conventions on top of existing `bd` commands.

2. **Standardize bead descriptions.** Every dispatched bead should include: goal, acceptance criteria, input references, and expected output format.

3. **Standardize close reasons.** Use the `Output:` / `Status:` format so downstream consumers can parse results programmatically.

4. **Add `bd ready --assignee <name>` to HEARTBEAT.md.** Each agent's heartbeat should filter for their own assignments, not just all open beads.

5. **Document patterns in beads-technical-guide.md.** Add a "Collaboration Patterns" section with the four patterns from §4.

6. **Revisit at 10+ agents.** When we outgrow these conventions, Gas Town's convoy and hook patterns are the natural next step. Until then, keep it simple.

## 7. References

1. steveyegge/beads — Git-backed distributed issue tracker. [github.com/steveyegge/beads](https://github.com/steveyegge/beads)
2. steveyegge/gastown — Multi-agent workspace manager. [github.com/steveyegge/gastown](https://github.com/steveyegge/gastown)
3. Agent Flywheel — Agentic coding environment setup. [agent-flywheel.com](https://agent-flywheel.com/)
4. Dicklesworthstone/mcp_agent_mail — Agent mailbox system. [github.com/Dicklesworthstone/mcp_agent_mail](https://github.com/Dicklesworthstone/mcp_agent_mail)
5. #B4mad Beads Technical Guide — Internal documentation. `brenner-axiom/docs/beads-technical-guide.md`
