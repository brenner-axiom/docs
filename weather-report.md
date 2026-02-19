# AI Weather Report

Source: [StrongDM Software Factory Weather Report](https://factory.strongdm.ai/weather-report) | Last synced: 2026-02-19

## StrongDM Model Usage (as of February 13th, 2026)

| Use | Models (by preference) | Parameters | Notes |
|-----|----------------------|------------|-------|
| CS/Math Hard Problems | gpt-5.3-codex | default | |
| Image comprehension | gemini-3-flash-preview | default | |
| Frontend Aesthetics | opus-4.6 | default | |
| Frontend Architecture | gpt-5.3-codex | default | |
| Architectural Critique | gpt-5.2 | extra high | |
| Sprint Planning | consensus(opus-4.6, gpt-5.2) | high / extra high | Consensus operator: LLM merge of independent plans |
| Devops Tasks | opus-4.6 | default | |
| QA Orchestration | opus-4.6 | default | |
| Security review | gpt-5.3-codex | high | |
| Bulk classification | Any | default | Go up cost and strength as needed |
| Bulk MapReduce | Any | default | Go up cost and strength as needed |
| UX Ideation | gemini-3-pro-image-preview | default | Nano Banana Pro |
| Agentic dialogues | gemini-3-flash-preview | default | General message handling loops with user interaction and limited tool calling |
| Voice (interactive) | gpt-realtime-mini | default | |

## #B4mad Fleet — Current Model Map

| Agent | Role | Primary Model | Fallback Model |
|-------|------|--------------|----------------|
| 🌐 Brenner Axiom | Orchestrator | Gemini 2.5 Pro | Opus 4.6 |
| 🐵 CodeMonkey | Coding Specialist | qwen3-coder:30b (local) | — |
| 🔧 PltOps | DevOps/SRE | qwen3-coder:30b (local) | — |
| 🎹 Romanov | Research Agent | Opus 4.6 | Gemini 2.5 Pro |
| ☕ Brew | URL Summarizer | Haiku 4.5 | — |
| 📰 LinkedIn Brief | Feed Monitor | Haiku 4.5 | — |
| 📿 Beads Ingest | GitHub→Bead Pipeline | qwen3-coder:30b (local) | — |
| 🌿 Lotti | Garden & Home | qwen3-coder:30b (local) | — |

## Model Overlap

| StrongDM Model | #B4mad Agent(s) | Our Usage |
|----------------|-----------------|-----------|
| **opus-4.6** | 🌐 Brenner Axiom (fallback), 🎹 Romanov (primary) | Research, orchestration fallback, DevOps critique |

StrongDM uses opus-4.6 for Frontend Aesthetics, DevOps Tasks, QA Orchestration, and Sprint Planning consensus. We use it for deep research (Romanov) and as Brenner's fallback.

No other direct model overlaps — StrongDM runs GPT-5.x and Gemini 3.x variants we haven't adopted.

## 🔮 Recommendations

### 🌐 Brenner Axiom — Currently Gemini 2.5 Pro → Opus 4.6
**Comparable StrongDM use cases:** Agentic dialogues, Sprint Planning
**StrongDM uses:** gemini-3-flash-preview (agentic dialogues), consensus(opus-4.6, gpt-5.2) (planning)
**Recommendation: KEEP**
Gemini 2.5 Pro is cost-effective for orchestration. StrongDM uses gemini-3-flash for agentic loops, confirming the Gemini family works well here. Consider upgrading to Gemini 3 Flash when available for tool-calling improvements.

### 🐵 CodeMonkey — Currently qwen3-coder:30b (local)
**Comparable StrongDM use cases:** Frontend Architecture, CS/Math Hard Problems, DevOps Tasks
**StrongDM uses:** gpt-5.3-codex (architecture, CS/math), opus-4.6 (DevOps)
**Recommendation: EVALUATE**
StrongDM's primary coding model is gpt-5.3-codex and they're "very happy" with it. For routine code tasks, local qwen3-coder saves cost. If code quality issues arise on complex tasks (architecture, hard algorithms), gpt-5.3-codex is worth benchmarking. Consider a tiered approach: local for routine, API for hard problems.

### 🔧 PltOps — Currently qwen3-coder:30b (local)
**Comparable StrongDM use cases:** DevOps Tasks, Security review
**StrongDM uses:** opus-4.6 (DevOps), gpt-5.3-codex with high params (security)
**Recommendation: EVALUATE**
StrongDM trusts opus-4.6 for DevOps and gpt-5.3-codex for security reviews. Our local model is fine for Ansible/CI/CD templating, but security-sensitive reviews may benefit from a stronger model. Consider routing security-critical tasks to Opus 4.6.

### 🎹 Romanov — Currently Opus 4.6 → Gemini 2.5 Pro
**Comparable StrongDM use cases:** Architectural Critique, Sprint Planning
**StrongDM uses:** gpt-5.2 with extra high params (critique), consensus(opus-4.6, gpt-5.2) (planning)
**Recommendation: KEEP**
Opus 4.6 aligns with StrongDM's choices for critique and planning. They pair it with gpt-5.2 in a consensus operator for planning — we could experiment with a similar dual-model approach for research papers (Opus draft + Gemini critique).

### ☕ Brew — Currently Haiku 4.5
**Comparable StrongDM use cases:** Bulk classification
**StrongDM uses:** Any (go up cost and strength as needed)
**Recommendation: KEEP**
URL summarization is a lightweight task. StrongDM says "any" model works for bulk classification. Haiku 4.5 is the right cost/performance tradeoff.

### 📰 LinkedIn Brief — Currently Haiku 4.5
**Comparable StrongDM use cases:** Bulk classification, Agentic dialogues
**StrongDM uses:** Any (bulk), gemini-3-flash-preview (agentic dialogues)
**Recommendation: KEEP**
Feed monitoring is bulk classification territory. If we add interactive response drafting, gemini-3-flash-preview would be worth considering for that component.

### 📿 Beads Ingest — Currently qwen3-coder:30b (local)
**Comparable StrongDM use cases:** Bulk MapReduce
**StrongDM uses:** Any
**Recommendation: KEEP**
Pipeline ingestion is exactly "Bulk MapReduce" — StrongDM says any model works. Local qwen3-coder is ideal for this high-volume, low-complexity work.

### 🌿 Lotti — Currently qwen3-coder:30b (local)
**Comparable StrongDM use cases:** No direct equivalent
**Recommendation: KEEP**
Personal/home tasks don't need frontier models. Local model is perfect.

## Key Takeaways

- **Consensus operators for planning**: StrongDM now uses a multi-model consensus approach (opus-4.6 + gpt-5.2) for Sprint Planning. We could experiment with this for bead triage or sprint planning — have two models independently plan, then merge.
- **Gemini 3 for agentic loops**: StrongDM adopted gemini-3-flash-preview specifically for agentic dialogues with tool calling. When Gemini 3 Flash becomes available to us, it's a strong candidate for Brenner Axiom's primary model.
- **gpt-5.3-codex dominance in coding**: StrongDM's strongest endorsement is for gpt-5.3-codex across coding tasks. Our local qwen3-coder handles routine work, but we should benchmark gpt-5.3-codex for CodeMonkey's harder tasks to see if the quality gap justifies API costs.
