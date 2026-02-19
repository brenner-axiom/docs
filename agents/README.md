# 🚀 Meet the Fleet

> *The autonomous agent roster of **#B4mad Industries**.*
>
> Eight agents. One mission. Technological sovereignty, open source ethos, and work that ships.

<p align="center"><code style="color: #458B74">━━━ #458B74 · DarkSeaGreen4 · The color of trust ━━━</code></p>

## The Roster

| | Agent | Role | Primary Model | Fallback Strategy | Workspace |
|---|---|---|---|---|---|
| 🌐 | [**Brenner Axiom**](brenner-axiom.md) | Orchestrator | Gemini 2.5 Pro | → Opus 4.6 → Gemini Flash | [axiom-workspace](https://github.com/brenner-axiom/axiom-workspace) |
| 🐵 | [**CodeMonkey**](codemonkey.md) | Coding Specialist | qwen3-coder:30b (local) | → Gemini Flash → Gemini Pro | [codemonkey/](https://github.com/brenner-axiom) |
| 🔧 | [**PltOps**](pltops.md) | DevOps / SRE | qwen3-coder:30b (local) | → Gemini Flash → Gemini Pro | pltops/ |
| 🎹 | [**Romanov**](romanov.md) | Research Agent | Opus 4.6 | → Gemini 2.5 Pro | [romanov-research](https://codeberg.org/brenner-axiom/romanov-research) |
| ☕ | [**Brew**](brew.md) | URL Summarizer | Haiku 4.5 | → Gemini Flash → Gemini Pro | brew/ |
| 📰 | [**LinkedIn Brief**](linkedin-brief.md) | Feed Monitor | Haiku 4.5 | → Gemini Flash → Gemini Pro | linkedin-brief/ |
| 📿 | [**Beads Ingest**](beads-ingest.md) | GitHub→Bead Pipeline | qwen3-coder:30b (local) | → Gemini Flash | beads-ingest/ |
| 🌿 | [**Lotti**](lotti.md) | Garden & Home | qwen3-coder:30b (local) | → Gemini Flash | lotti/ |

### Model Tiers

| Tier | Model | Provider | Cost | Use Case |
|---|---|---|---|---|
| 🧠 Frontier | Claude Opus 4.6 | Anthropic | $$$ | Research, orchestration fallback |
| ⚡ Fast Cloud | Gemini 2.5 Pro | Google | $$ | Orchestration primary, broad research |
| 💨 Light Cloud | Gemini 2.5 Flash | Google | $ | Fast fallback, simple tasks |
| 🏠 Local | qwen3-coder:30b | Ollama (local) | Free | Coding, DevOps, pipelines — zero latency, full privacy |
| 🪶 Light Cloud | Haiku 4.5 | Anthropic | $ | Summaries, feed monitoring |

### Fallback Strategy

Every agent has a **fallback chain**. If the primary model is unavailable (rate limit, cooldown, outage), OpenClaw automatically tries the next model in the chain. This ensures:

- **No single point of failure** — work continues even if a provider goes down
- **Cost optimization** — expensive models only used when needed
- **Local-first where possible** — coding agents default to local qwen3-coder (free, private, fast)

### Delegation Rules

Brenner Axiom can spawn the following agents as sub-agents:

```
main → codemonkey, linkedin-brief, beads-ingest, brew, pltops, lotti, romanov
```

Dispatch is automatic via HEARTBEAT.md:
- **Research:** prefix → 🎹 Romanov
- **GitHub/cluster/CI:** → 🔧 PltOps  
- **Code/scripts/features:** → 🐵 CodeMonkey
- **URLs:** → ☕ Brew
- **Default:** → 🐵 CodeMonkey

## How It Works

Every agent coordinates through **[Beads](https://github.com/steveyegge/beads)** — a git-backed task graph with full traceability. No black boxes. No hidden state. Every action logged, every decision auditable.

**Brenner Axiom** is the conductor. Work comes in, gets triaged into beads, and dispatched to the right specialist. Results flow back through Signal notifications, PR updates, and bead closures.

### Communication Channels

- **Signal** — Primary human↔agent channel
- **Beads** — Inter-agent task coordination
- **Git** — The audit trail and source of truth
- **PRs & Issues** — Code review and collaboration on Codeberg/GitHub

### Scheduled Jobs

| Schedule | Agent | Job |
|---|---|---|
| Every 20 min | 📿 Beads Ingest | GitHub issue → Bead ingestion |
| Every 30 min | 🌐 Brenner | Workspace git sync |
| 3× daily (8/13/18h) | 📰 LinkedIn Brief | Feed monitoring + Signal delivery |
| Weekly (Fri 8:30) | 🌐 Brenner | Shopping list → Signal group |
| Daily (11:00) | 🌐 Brenner | Info Scout article summaries |
| Bi-weekly (Sun 10:00) | 🌐 Brenner | OKR progress review |

### Core Principles

- 🔒 **Security-first** — Access earned, not assumed. Secrets in gopass, tools allowlisted.
- 📝 **Transparency** — Memory in markdown, everything in git
- 🤖 **Agent-first semantics** — Unambiguous, structured, deterministic
- 🌍 **Open source ethos** — GPLv3, community over corporate control
- 💰 **Cost-aware** — Local models where possible, budget caps on expensive agents (Romanov: 33% Opus limit)

---

<p align="center"><em>Part of the <strong>#B4mad Network</strong> · Built for <strong>goern</strong> · Powered by opinions and open standards</em></p>
