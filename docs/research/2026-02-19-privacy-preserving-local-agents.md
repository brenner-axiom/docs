# Privacy-Preserving Multi-Agent Architecture with Local Models

**Author:** Roman "Romanov" Research-Rachmaninov  
**Date:** 2026-02-19  
**Bead:** beads-hub-pe1  
**Status:** Final

## Abstract

This paper investigates whether #B4mad can run its entire multi-agent system—Brenner Axiom, CodeMonkey, PltOps, Romanov—on local open-weight models with zero cloud dependency for sensitive workloads. We evaluate the current landscape of local inference (Qwen3-Coder-Next, Llama-based routers, Ollama), assess where local models can replace cloud APIs today, and propose a minimum viable architecture. Our finding: **local models can handle ~80% of agent tasks** (code generation, bead management, routine ops) with Qwen3-Coder-Next (80B/3B-active MoE) as the workhorse, but deep reasoning tasks (complex research, multi-step strategic analysis) still benefit from cloud-tier models. We recommend a tiered architecture: local-first with optional cloud escalation, governed by data sensitivity classification.

## 1. Context: Why This Matters for #B4mad

#B4mad already stores all agent memory in markdown files backed by git. This is a strong privacy foundation—memory never leaves the machine unless explicitly pushed. But inference still flows through cloud APIs (Anthropic Claude, Google Gemini), meaning every agent prompt, every bead description, every piece of context is transmitted externally.

This creates three risks:
1. **Data exposure**: Sensitive work orders, personal context from `MEMORY.md`, infrastructure details from `TOOLS.md`—all sent to third-party inference providers.
2. **Vendor lock-in**: If Anthropic or Google change pricing, rate-limit, or deprecate models, the entire agent fleet stops.
3. **Availability dependency**: Cloud outages halt all agent work, even for tasks that don't require frontier reasoning.

The Lex Fridman #490 podcast (AI State of the Art 2026, ~34:46) captured the sentiment well: users want separate work/personal AI contexts, local customization, and the ability to add data post-training without it leaving their machine. This aligns exactly with #B4mad's agent-first philosophy.

Our recently published pull-based scheduling paper (beads-hub-30f) already describes agents polling a local bead board. The natural next step: those agents running on local models, with the bead board as the only coordination surface, and no data leaving the machine.

## 2. State of the Art: Local Inference for Agent Workloads

### 2.1 Qwen3-Coder Family

The Qwen3-Coder family represents the current state-of-the-art for local agentic coding:

- **Qwen3-Coder-480B-A35B-Instruct**: Flagship MoE model, 480B total / 35B active parameters. Performance comparable to Claude Sonnet 4 on SWE-Bench, agentic coding, and tool use. Requires ~70GB VRAM (quantized) — feasible on a dual-GPU workstation but not casual hardware.
- **Qwen3-Coder-Next (80B-A3B)**: The local-first variant. 80B total / 3B active parameters with hybrid attention and MoE. Designed explicitly for coding agents and local development. Runs comfortably on a single consumer GPU (16GB+ VRAM at Q4 quantization). Trained with large-scale agentic RL including environment interaction.
- **Qwen3-Coder-30B-A3B-Instruct**: Mid-tier option, 30B/3B-active. Good balance of capability and resource requirements.

Key capabilities relevant to #B4mad:
- 256K native context (1M with YaRN extrapolation) — sufficient for repo-scale understanding
- Native function calling / tool use — critical for agent frameworks
- 358 programming language support
- Available via Ollama: `ollama run qwen3-coder`

### 2.2 Routing and Orchestration Models

For the "small routing model" that dispatches tasks to specialists:

- **Qwen3-0.6B / 1.7B**: Tiny models suitable for classification tasks (intent detection, bead routing, priority assessment). Can run on CPU.
- **Llama-3.2-3B**: Strong general-purpose small model for routing decisions.
- **Phi-4-mini (3.8B)**: Microsoft's compact model with strong reasoning for its size.
- **RouteLLM** (open-source project): Framework for routing between strong/weak models based on query complexity. Directly applicable to our local/cloud tiering.

### 2.3 Inference Infrastructure

- **Ollama**: De facto standard for local model serving. OpenAI-compatible API, easy model management, quantization support. Already in use at #B4mad (`custom-10-144-28-67-11434/qwen3-coder-next:latest`).
- **llama.cpp / llama-server**: Lower-level but more configurable. Supports speculative decoding (small draft model + large verify model) for faster inference.
- **vLLM**: High-throughput serving with PagedAttention. Better for concurrent agent requests but heavier setup.
- **LocalAI**: OpenAI-compatible API server supporting multiple backends.

### 2.4 Privacy-Preserving Approaches in the Literature

- **Federated learning** (McMahan et al., 2017): Training across distributed nodes without sharing data. Relevant for future multi-node #B4mad setups.
- **Differential privacy in LLM inference** (various 2024-2025): Adding noise to prevent memorization. Less relevant for our use case since we control the entire pipeline.
- **Confidential computing** (Intel SGX, AMD SEV): Hardware-level isolation for sensitive inference. Overkill for our threat model but worth noting.
- **On-device AI** (Apple Intelligence, Google Gemini Nano): Industry trend toward local inference for privacy. Validates our approach.

## 3. Analysis: Can Local Models Replace Cloud APIs for 80% of Agent Tasks?

### 3.1 Task Taxonomy

We categorize #B4mad agent tasks by complexity and map them to model requirements:

| Task Category | Examples | Required Capability | Local Feasible? |
|---|---|---|---|
| **Bead management** | Create, update, close beads; parse status | Structured output, tool calling | ✅ Yes — any 3B+ model |
| **Code generation** | Scripts, configs, Ansible playbooks | Coding, context understanding | ✅ Yes — Qwen3-Coder-Next excels |
| **Code review / PR feedback** | Review diffs, suggest changes | Code understanding, reasoning | ✅ Yes — Qwen3-Coder-Next |
| **Git operations** | Commit messages, branch management | Template following | ✅ Yes — trivial |
| **Routing / dispatch** | Classify incoming requests, assign to agents | Intent classification | ✅ Yes — 1-3B router model |
| **URL summarization** | Fetch and summarize web content | Reading comprehension | ✅ Yes — 7B+ model |
| **Infrastructure ops** | kubectl, oc commands, monitoring checks | Tool use, structured output | ✅ Yes — Qwen3-Coder-Next |
| **Conversational interaction** | Chat with goern, group discussions | Natural language, personality | ⚠️ Mostly — but nuance/humor degrades |
| **Deep research** | Literature review, multi-source synthesis | Long-context reasoning, depth | ❌ Not yet — Opus-tier still needed |
| **Complex strategic analysis** | Architecture decisions, trade-off papers | Deep reasoning, creativity | ❌ Not yet — frontier models preferred |

**Estimate: 75-85% of daily agent tasks are locally feasible today.**

### 3.2 The Qwen3-Coder-Next Sweet Spot

Qwen3-Coder-Next (80B/3B-active) is the ideal workhorse for #B4mad because:

1. **MoE efficiency**: Only 3B parameters active per token despite 80B total knowledge. This means near-3B inference cost with much higher capability.
2. **Agentic training**: Specifically trained with long-horizon RL on real-world agent tasks, environment interaction, and tool use. Not just a code completer—it's an agent model.
3. **Ollama integration**: Already supported, already deployed at #B4mad's inference endpoint.
4. **256K context**: Enough to hold an entire bead board + memory files + current task context.

### 3.3 Where Local Falls Short

Two categories remain cloud-dependent:

1. **Deep research (Romanov tasks)**: Synthesizing across multiple sources, producing nuanced analysis with original insights, evaluating trade-offs at a strategic level. Qwen3-Coder-Next can produce *adequate* research but not Opus-quality depth. This is the 15-20% that still needs cloud.

2. **Personality-rich interaction**: Brenner's main session conversations with goern require wit, cultural awareness, and emotional intelligence that smaller models handle less gracefully. Acceptable for task execution but not for the "personal assistant with personality" use case.

### 3.4 The Router Model Question

Can a small model (0.6B-3B) effectively route tasks to the right agent? Yes, because:

- Bead titles already contain routing hints ("Research:", code tasks, ops tasks)
- The routing decision is a classification task, not a generation task
- A fine-tuned Qwen3-0.6B on #B4mad's historical bead assignments would likely achieve >95% routing accuracy
- Even without fine-tuning, a prompted 1.7B model can classify intent reliably

**Proposed router**: Qwen3-1.7B with a system prompt describing each agent's capabilities. Input: bead title + description. Output: agent assignment + priority. Runs on CPU, <2GB RAM.

## 4. Proposed Architecture: Local-First with Cloud Escalation

### 4.1 System Overview

```
┌─────────────────────────────────────────────────────┐
│                   Local Machine                      │
│                                                      │
│  ┌──────────┐    ┌──────────────────────────────┐   │
│  │  Router   │    │         Ollama Server         │   │
│  │ (1.7B)   │───▶│  ┌────────────────────────┐  │   │
│  └──────────┘    │  │ Qwen3-Coder-Next (3B)  │  │   │
│       ▲          │  └────────────────────────┘  │   │
│       │          └──────────────────────────────┘   │
│       │                       │                      │
│  ┌────┴────┐          ┌──────┴──────┐               │
│  │  Bead   │          │   Agents    │               │
│  │  Board  │◀────────▶│ (OpenClaw)  │               │
│  │  (git)  │          │             │               │
│  └─────────┘          └──────┬──────┘               │
│                              │                       │
│                    ┌─────────┴──────────┐           │
│                    │ Sensitivity Gate   │           │
│                    │ (local policy)     │           │
│                    └─────────┬──────────┘           │
└──────────────────────────────┼───────────────────────┘
                               │ (only if needed AND allowed)
                        ┌──────┴──────┐
                        │  Cloud API  │
                        │ (Opus/etc)  │
                        └─────────────┘
```

### 4.2 Components

**1. Local Router (Qwen3-1.7B on CPU)**
- Classifies incoming beads/messages
- Routes to appropriate local agent
- Flags tasks that may need cloud escalation

**2. Primary Inference (Qwen3-Coder-Next via Ollama)**
- Handles all code, ops, bead management, and routine conversation
- Serves CodeMonkey, PltOps, and routine Brenner tasks
- Single GPU (RTX 4090 / RTX 5090 or equivalent)

**3. Bead Board (git-backed, local)**
- Already implemented — no changes needed
- Pull-based scheduling as described in our previous paper
- Agents poll, claim, execute, close

**4. Memory Layer (markdown files, git-backed)**
- Already implemented — `MEMORY.md`, `memory/*.md`, `AGENTS.md`
- Zero cloud dependency, full local control
- Git provides versioning, sync is explicit

**5. Sensitivity Gate (local policy engine)**
- Simple rule-based classifier:
  - Contains personal data? → Local only
  - Contains infrastructure secrets? → Local only
  - Requires deep reasoning? → May escalate to cloud
  - Research task? → May escalate to cloud
- User can override: `--local-only` flag forces all-local

**6. Cloud Escalation (optional)**
- Only for tasks that pass the sensitivity gate AND require frontier capability
- User explicitly approves cloud usage per-task or per-category
- Could be eliminated entirely if accepting quality trade-off on research/deep reasoning

### 4.3 Minimum Viable Local Setup

| Component | Hardware | Cost (approx.) |
|---|---|---|
| GPU | NVIDIA RTX 4090 (24GB VRAM) | ~$1,600 |
| CPU | Any modern 8-core (for router model) | (existing) |
| RAM | 32GB+ | (existing) |
| Storage | 500GB SSD (models + repos) | ~$50 |
| Software | Ollama + OpenClaw + git | Free |

**Total incremental cost: ~$1,650** (assuming existing workstation; just add GPU)

For the budget-conscious: an RTX 4070 Ti Super (16GB) can run Qwen3-Coder-Next at Q4 quantization with acceptable speed. Cost: ~$800.

For maximum capability: dual RTX 4090 or single RTX 5090 (32GB) allows running the 30B-A3B variant at higher quantization or the full 480B-A35B with aggressive quantization.

### 4.4 Model Configuration

```yaml
# Proposed Ollama model configuration
models:
  router:
    name: qwen3:1.7b
    purpose: Intent classification, bead routing
    hardware: CPU only
    memory: ~2GB RAM
    
  workhorse:
    name: qwen3-coder-next:latest
    purpose: Code, ops, bead management, conversation
    hardware: GPU (RTX 4090)
    memory: ~14GB VRAM (Q4_K_M)
    context: 32768  # expandable to 256K if needed
    
  summarizer:
    name: qwen3:7b
    purpose: URL summarization (Brew agent)
    hardware: CPU or shared GPU
    memory: ~5GB
```

## 5. Migration Path

### Phase 1: Shadow Mode (Weeks 1-2)
- Run local models alongside cloud APIs
- Compare outputs for quality regression
- Measure latency and throughput
- Identify tasks where local quality is unacceptable

### Phase 2: Local-Default (Weeks 3-4)
- Switch CodeMonkey and PltOps to local inference
- These are the most tool-use heavy, least personality-dependent agents
- Keep Brenner main session and Romanov on cloud

### Phase 3: Full Local with Cloud Escalation (Weeks 5-8)
- Move Brenner routine tasks to local
- Implement sensitivity gate
- Cloud only for: Romanov deep research, complex Brenner conversations
- Measure cloud API cost reduction (target: 80%+ reduction)

### Phase 4: Evaluate Full Local (Ongoing)
- As local models improve (Qwen4, Llama 4, etc.), reassess cloud necessity
- Fine-tune router on accumulated #B4mad data
- Consider fine-tuning workhorse model on #B4mad-specific patterns

## 6. Connection to Pull-Based Scheduling

This architecture completes the vision outlined in our pull-based scheduling paper:

1. **Bead board** serves as the shared work queue (already implemented)
2. **Agents poll** for tasks matching their capabilities (described in previous paper)
3. **All inference is local** (this paper's contribution)
4. **All memory is local markdown** (already implemented)

The result: a fully self-contained multi-agent system where:
- No data leaves the machine unless explicitly pushed to git remotes
- No cloud dependency for routine operations
- Agents are autonomous, self-scheduling, and privacy-preserving
- The only external dependency is git hosting (which can also be self-hosted)

## 7. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Local model quality regression on edge cases | High | Medium | Shadow mode testing; cloud escalation path |
| GPU failure = all agents down | Medium | High | CPU fallback (slower but functional); spare GPU |
| Model updates break agent prompts | Medium | Medium | Pin model versions; test before upgrading |
| Context window insufficient for complex tasks | Low | Medium | Qwen3-Coder-Next supports 256K natively |
| Ollama instability under concurrent load | Medium | Medium | Rate limiting; vLLM as alternative backend |

## 8. Recommendations

1. **Adopt Qwen3-Coder-Next as the primary local model** for CodeMonkey, PltOps, and routine Brenner tasks. It is purpose-built for agentic workloads and runs efficiently on consumer hardware.

2. **Deploy Qwen3-1.7B as the router** on CPU. It costs nothing in GPU resources and can classify/route with high accuracy.

3. **Start with Phase 1 (shadow mode)** immediately. The infrastructure is already in place—Ollama is running, models are available, OpenClaw supports custom model endpoints.

4. **Keep cloud escalation for Romanov and complex Brenner tasks** until local models close the reasoning gap. Budget for ~20% cloud usage.

5. **Implement the sensitivity gate** as a simple rule-based policy before any cloud calls. This is the key privacy guarantee.

6. **Self-host git** (Forgejo on Nostromo) to eliminate the last external dependency. This makes the system fully air-gappable for maximum-security deployments.

7. **Track the Qwen3-Coder evolution**: The family is rapidly improving. The gap between Qwen3-Coder-Next and Claude Opus is narrowing. Re-evaluate quarterly.

## 9. Conclusion

#B4mad is uniquely positioned to offer a privacy-preserving multi-agent system. The foundation is already laid: markdown-based memory, git-backed bead coordination, pull-based scheduling. The missing piece—local inference—is now viable thanks to Qwen3-Coder-Next and efficient MoE architectures.

The answer to "Can Qwen3-Coder + a small routing model replace cloud APIs for 80% of agent tasks?" is **yes, today**. The minimum viable setup is a single RTX 4090, Ollama, and the models described in this paper. The 20% that still benefits from cloud (deep research, complex reasoning) can be handled via an explicit escalation path with sensitivity controls.

The vision of agents polling a local bead board, running on local models, with no data leaving the machine is not aspirational—it is achievable with current technology and #B4mad's existing architecture.

## References

1. Qwen Team, "Qwen3-Coder: Agentic Coding in the World," 2026. https://qwenlm.github.io/blog/qwen3-coder/
2. Qwen Team, "Qwen3-Coder-Next: Pushing Small Hybrid Models on Agentic Coding," 2026. https://github.com/QwenLM/Qwen3-Coder
3. Romanov, "Pull-Based Agent Scheduling Architecture for #B4mad," 2026. Internal paper, beads-hub-30f.
4. Lex Fridman Podcast #490, "AI State of the Art 2026," ~34:46. Discussion on local inference and data privacy.
5. McMahan et al., "Communication-Efficient Learning of Deep Networks from Decentralized Data," AISTATS 2017.
6. Ollama Project, https://ollama.com/
7. RouteLLM Project, "A framework for LLM routing," 2024. https://github.com/lm-sys/RouteLLM
8. OpenClaw Documentation, https://openclaw.com/
