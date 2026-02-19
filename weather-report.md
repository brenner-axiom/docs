# AI Weather Report

Source: [StrongDM Software Factory Weather Report](https://factory.strongdm.ai/weather-report)

Last synced: 2026-02-19

## StrongDM Model Usage (as of February 13th, 2026)

| Use | Models (by preference) | Parameters | Notes |
|-----|----------------------|------------|-------|
| CS/Math Hard Problems | gpt-5.3-codex | default | |
| Image comprehension | gemini-3-flash-preview | default | |
| Frontend Aesthetics | opus-4.6 | default | |
| Frontend Architecture | gpt-5.3-codex | default | |
| Architectural Critique | gpt-5.2 | extra high | |
| Sprint Planning | consensus(opus-4.6, gpt-5.2) | high / extra high | |
| Devops Tasks | opus-4.6 | default | |
| QA Orchestration | opus-4.6 | default | |
| Security review | gpt-5.3-codex | high | |
| Bulk classification | Any | default | Go up cost and strength as needed |
| Bulk MapReduce | Any | default | Go up cost and strength as needed |
| UX Ideation | gemini-3-pro-image-preview | default | Nano Banana Pro |
| Agentic dialogues | gemini-3-flash-preview | default | General message handling loops with user interaction and limited tool calling |
| Voice (interactive) | gpt-realtime-mini | default | |

> Consensus operator refers to an LLM merge of the points from independent plans.

## #B4mad Fleet Model Overlap

Models from the StrongDM report that are also used by #B4mad agents:

| StrongDM Model | #B4mad Agent(s) | Our Usage |
|----------------|-----------------|-----------|
| **opus-4.6** | 🌐 Brenner Axiom (fallback), 🎹 Romanov (primary) | Romanov deep research; Brenner fallback reasoning |

### Models StrongDM uses that we don't

- `gpt-5.3-codex` — their primary implementation model (CS/math, frontend architecture, security review)
- `gpt-5.2` — architectural critique, sprint planning consensus
- `gemini-3-flash-preview` — image comprehension, agentic dialogues
- `gemini-3-pro-image-preview` — UX ideation
- `gpt-realtime-mini` — voice/interactive

### #B4mad models not in StrongDM's report

- **Gemini 2.5 Pro** — Brenner Axiom primary (StrongDM uses newer Gemini 3 variants)
- **qwen3-coder:30b** (local) — CodeMonkey, PltOps, Beads Ingest, Lotti
- **Haiku 4.5** — Brew, LinkedIn Brief
