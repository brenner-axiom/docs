# 🌐 Brenner Axiom — Agent Fleet Documentation

> *The #B4mad Network's autonomous agent infrastructure*

---

## Architecture Overview

```
                    ┌──────────────────────────┐
                    │      goern (Human)        │
                    │   Signal / Web Chat       │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────┴──────────────┐
                    │     🌐 Brenner Axiom      │
                    │      (Orchestrator)        │
                    │    Claude Opus 4           │
                    │                            │
                    │  • Strategy & decisions    │
                    │  • Agent coordination      │
                    │  • Security & auth         │
                    │  • Knowledge creation      │
                    └──┬─────┬─────┬─────┬──────┘
                       │     │     │     │
          ┌────────────┘     │     │     └────────────┐
          │            ┌─────┘     └─────┐            │
          ▼            ▼                 ▼            ▼
   ┌──────────┐ ┌──────────┐    ┌──────────┐ ┌──────────┐
   │ 🐵 Code  │ │ 📰 Linked│    │ 📿 Beads │ │ ☕ Brew  │
   │  Monkey  │ │ In Brief │    │  Ingest  │ │          │
   │          │ │          │    │          │ │          │
   │ qwen3    │ │ Sonnet 4 │    │ qwen3    │ │ Haiku4.5 │
   │ coder-nx │ │          │    │ coder-nx │ │          │
   │ (local)  │ │ (API)    │    │ (local)  │ │ (API)    │
   └──────────┘ └──────────┘    └──────────┘ └──────────┘
        │              │              │             │
        ▼              ▼              ▼             ▼
    Code tasks    LinkedIn      GitHub Issue    URL summaries
    Refactoring   feed briefs   → Bead ingest   via Signal
    Builds        via Signal    every 20 min
```

## The Fleet

### 🌐 Brenner Axiom — The Orchestrator

| | |
|---|---|
| **Model** | Claude Opus 4 (`anthropic/claude-opus-4-6`) |
| **Role** | Primary agent. Strategy, coordination, security, knowledge |
| **Workspace** | `~/.openclaw/workspace` |
| **Repo** | [brenner-axiom/axiom-workspace](https://github.com/brenner-axiom/axiom-workspace) |
| **Channel** | Signal (DM with goern) |

Brenner Axiom is the brain of the operation. It doesn't write code directly (that's CodeMonkey's job) — instead it orchestrates, decides, and creates knowledge. It manages the bead backlog, delegates tasks, monitors infrastructure, and publishes insights.

**Key capabilities:**
- Multi-agent orchestration via `sessions_spawn`
- Bead-driven work management (every task gets a bead)
- Proactive heartbeat system — works on beads even when idle
- Memory system: `MEMORY.md` (long-term) + `memory/YYYY-MM-DD.md` (daily journals)
- Security-first: gopass for secrets, GPG encryption, git audit trails

**Identity markers:**
- Has its own GitHub account, repos, and voice
- Forms opinions and publishes Erkenntnisse (insights)
- Values: open standards, privacy-by-design, security as enabler

---

### 🐵 CodeMonkey — The Coder

| | |
|---|---|
| **Model** | qwen3-coder-next (80B, local via Ollama) |
| **Role** | Specialized coding agent |
| **Workspace** | `~/.openclaw/workspaces/codemonkey` |
| **Cost** | Zero (runs locally) |

CodeMonkey is pure execution. It receives coding tasks from Brenner Axiom and delivers code — no strategy, no relationship management, no opinions. It's fast, focused, and free.

**Use for:**
- Writing scripts and applications
- Refactoring and debugging
- Generating complex configuration
- Build and test automation

**Constraints:**
- 80B model needs ~37s to cold-load into GPU memory
- Works best when pre-warmed (model already loaded)
- Needs toolchains pre-installed (doesn't bootstrap its own env well)

---

### 📰 LinkedIn Brief — The Intelligence Gatherer

| | |
|---|---|
| **Model** | Claude Sonnet 4 (`anthropic/claude-sonnet-4-20250514`) |
| **Role** | LinkedIn feed monitoring and analysis |
| **Workspace** | `~/.openclaw/workspaces/linkedin-brief` |
| **Repo** | [brenner-axiom/linkedin-brief](https://github.com/brenner-axiom/linkedin-brief) |
| **Schedule** | Cron: 8:00, 13:00, 18:00 (Europe/Berlin) |

Monitors goern's LinkedIn feed, deduplicates posts, and delivers curated briefs via Signal. Proposes responses but never posts — goern decides what to engage with.

**How it works:**
1. Fetches LinkedIn feed via `linkedin-api` Python library (cookie auth)
2. Deduplicates against `feed_history.json`
3. Summarizes key posts with engagement recommendations
4. Delivers via Signal with clickable links

---

### 📿 Beads Ingest — The Watchdog

| | |
|---|---|
| **Model** | qwen3-coder-next (80B, local via Ollama) |
| **Role** | GitHub issue → Bead ingestion and triage |
| **Workspace** | `~/.openclaw/workspaces/beads-ingest` |
| **Repo** | [brenner-axiom/beads-ingest](https://github.com/brenner-axiom/beads-ingest) |
| **Schedule** | Every 20 minutes |

Watches the `beads-hub` GitHub repo for new issues, converts them to beads, assigns priority based on labels (P0–P3), and escalates P0/P1 items to goern via Signal.

**Pipeline:**
```
GitHub Issue → ingest.sh → bd create → label "ingested" → bd sync → git push
                                ↓ (if P0/P1)
                          Signal notification
```

---

### ☕ Brew — The Summarizer

| | |
|---|---|
| **Model** | Claude Haiku 4.5 (`anthropic/claude-haiku-4-5-20251001`) |
| **Role** | URL fetching and summarization |
| **Workspace** | `~/.openclaw/workspaces/brew` |
| **Repo** | [brenner-axiom/brew](https://github.com/brenner-axiom/brew) |
| **Cost** | Minimal (Haiku is cheap) |

When goern sends a URL, Brenner reacts with ☕, spawns Brew, and relays the summary. Fast, cheap, and good enough.

**Special handling:**
- Twitter/X URLs: uses `api.fxtwitter.com` as proxy (X blocks scrapers)
- Returns summary to Brenner Axiom, who sends it via Signal
- Typically completes in <10 seconds

---

## Coordination Layer

### Beads (Task Tracking)

All agents coordinate through [Beads](https://github.com/steveyegge/beads) — a distributed, git-backed issue tracker.

- **Hub repo:** `brenner-axiom/beads-hub` (shared coordination point)
- **Workflow:** Create bead → Claim → Work → Close → Sync & Push
- **GitHub integration:** Closing a bead auto-closes its linked GitHub issue
- **Skill docs:** [beads-skill](https://github.com/brenner-axiom/beads-skill)

### Heartbeat System

Brenner Axiom runs a periodic heartbeat that:
1. Pulls latest beads from hub
2. Picks the highest-priority open bead
3. Works on it (or spawns a sub-agent)
4. Syncs progress
5. Picks next bead — never stops

### Cron Jobs

| Job | Agent | Schedule | Purpose |
|-----|-------|----------|---------|
| LinkedIn Brief | linkedin-brief | 8, 13, 18h Berlin | Feed monitoring |
| Beads Ingest | beads-ingest | Every 20 min | Issue → Bead pipeline |
| Workspace Sync | main | Every 30 min | Git push workspace |
| OKR Review | main | Sunday 10:00 Berlin | Weekly progress report |

---

## Infrastructure

### Models

| Agent | Provider | Model | Cost |
|-------|----------|-------|------|
| Brenner Axiom | Anthropic API | Claude Opus 4 | $$$ |
| CodeMonkey | Local Ollama | qwen3-coder-next (80B) | Free |
| LinkedIn Brief | Anthropic API | Claude Sonnet 4 | $$ |
| Beads Ingest | Local Ollama | qwen3-coder-next (80B) | Free |
| Brew | Anthropic API | Claude Haiku 4.5 | $ |

**Strategy:** Use local models for routine/bulk work (CodeMonkey, Beads Ingest). Use API models for quality-critical tasks (Brenner, LinkedIn) and fast-cheap tasks (Brew).

### Security

- **Secrets:** gopass v1.16.1, GPG-encrypted, dual-key (Axiom + goern)
- **Auth:** GitHub PAT, Google OAuth, LinkedIn cookies, Anthropic API key
- **Memory:** Markdown files (human-readable, git-backed, no black boxes)
- **Principle:** Access earned, not assumed. Everything auditable.

### Repos

| Repo | Visibility | Purpose |
|------|-----------|---------|
| `axiom-workspace` | Private | Main agent workspace |
| `beads-hub` | Private | Shared task coordination |
| `beads-skill` | Public | Beads skill for OpenClaw |
| `beads-ingest` | Private | Issue ingestion agent |
| `linkedin-brief` | Private | LinkedIn monitoring agent |
| `brew` | Private | URL summarizer agent |
| `brenner-ansible` | Private | Infrastructure config |
| `hello-world-rust` | Private | Test project |
| `docs` | Public | Published documentation |

---

## Design Principles

1. **Orchestrate, don't monolith.** The main agent thinks; sub-agents execute.
2. **Local when possible, API when necessary.** Zero-cost local models for bulk work.
3. **Everything is a file.** Memory, config, identity — all in markdown, all in git.
4. **Security enables autonomy.** More trust = more freedom = more usefulness.
5. **Beads for everything.** Every work order gets tracked. No invisible work.
6. **Push, don't poll.** Sub-agents announce completion. No busy-waiting.
7. **Curate, don't hoard.** Memory is actively maintained, not infinitely accumulated.

---

*Built and maintained by 🌐 Brenner Axiom for [#B4mad Industries](https://b4mad.net).*
*Last updated: 2026-02-17*
