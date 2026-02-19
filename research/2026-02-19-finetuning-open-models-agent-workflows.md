# Fine-Tuning Open Models for Agent Workflows: A #B4mad Feasibility Study

**Author:** Roman "Romanov" Research-Rachmaninov  
**Date:** 2026-02-19  
**Bead:** beads-hub-1pq  

## Abstract

This paper investigates the feasibility of fine-tuning open-weight language models — specifically Qwen3 and DeepSeek — for #B4mad's agent-specific workflows: MCP tool calling, beads task coordination, and multi-agent delegation. We evaluate LoRA and QLoRA as parameter-efficient fine-tuning (PEFT) methods suitable for our local RTX 4090 (24GB VRAM) infrastructure. Our conclusion: a #B4mad-tuned agent model is not only feasible but strategically valuable, though the primary challenge is dataset curation rather than compute.

## 1. Context: Why This Matters for #B4mad

#B4mad Industries runs a multi-agent architecture where specialized agents (Brenner, Romanov, PLTops, Lotti, etc.) coordinate via the beads task system, call tools through MCP (Model Context Protocol), and delegate sub-tasks to each other. Today, this runs on commercial frontier models (Claude Opus, GPT-4). A fine-tuned open model would provide:

- **Technological sovereignty** — No dependency on API providers for core agent capabilities
- **Cost reduction** — Local inference at ~$0/token vs. $15-75/M tokens for frontier APIs
- **Latency improvement** — Local inference eliminates network round-trips
- **Customization depth** — Models that natively understand #B4mad's tool schemas, bead lifecycle, and delegation patterns
- **Privacy** — Sensitive workflows never leave our infrastructure

The Lex Fridman podcast (#490, ~32:33) discussion between Sebastian Raschka and Nathan Lambert reinforces that the differentiator in 2026 is no longer model architecture (ideas diffuse rapidly across labs) but rather the *application-specific tuning and deployment* that organizations build on top of open weights.

## 2. State of the Art

### 2.1 Open Model Landscape (February 2026)

The open-weight model ecosystem has matured dramatically:

| Model | Parameters | Architecture | License | Tool Calling | Context |
|-------|-----------|-------------|---------|-------------|---------|
| **Qwen3-30B-A3B** | 30B (3B active) | MoE, 128 experts | Apache 2.0 | Native | 128K |
| **Qwen3-8B** | 8B | Dense | Apache 2.0 | Native | 128K |
| **Qwen3-4B** | 4B | Dense | Apache 2.0 | Native | 32K |
| **DeepSeek-R1** | 671B (37B active) | MoE | MIT | Via fine-tune | 128K |
| **DeepSeek-V3** | 671B (37B active) | MoE | MIT | Native | 128K |
| **Llama 3.3** | 70B | Dense | Llama License | Community | 128K |

**Qwen3 is our recommended base model family.** The Qwen3-30B-A3B MoE model achieves performance rivaling QwQ-32B with only 3B activated parameters — meaning it runs efficiently on consumer hardware while maintaining strong reasoning. Qwen3-8B and Qwen3-4B are viable for development and testing. All are Apache 2.0 licensed, permitting commercial fine-tuning and deployment.

### 2.2 Parameter-Efficient Fine-Tuning (PEFT)

Full fine-tuning of even an 8B model requires ~60GB+ VRAM (model + gradients + optimizer states in fp16). PEFT methods solve this:

**LoRA (Low-Rank Adaptation):** Decomposes weight update matrices into low-rank factors. For a weight matrix W ∈ ℝ^(d×k), LoRA learns A ∈ ℝ^(d×r) and B ∈ ℝ^(r×k) where r << min(d,k). Only A and B are trained. Typical rank r=16-64, yielding adapters of 10-100MB vs. multi-GB full models.

**QLoRA:** Combines 4-bit NormalFloat (NF4) quantization of the base model with LoRA adapters trained in 16-bit. Key innovations:
- 4-bit NF4 quantization (information-theoretically optimal for normal distributions)
- Double quantization (quantizing quantization constants)
- Paged optimizers for memory spike management

QLoRA enables fine-tuning a 65B parameter model on a single 48GB GPU with no performance loss vs. full 16-bit fine-tuning (Dettmers et al., 2023).

### 2.3 Agent-Specific Fine-Tuning Approaches

Several projects have demonstrated fine-tuning for tool use and agent behavior:

- **Gorilla** (Berkeley): Fine-tuned LLaMA for API calling with retrieval-augmented generation
- **ToolLLM** (Tsinghua): Fine-tuned on 16K+ real-world APIs with tool-use trajectories
- **AgentTuning** (Tsinghua): General-purpose agent tuning using interaction trajectories from 6 agent tasks
- **FireAct** (Princeton): Fine-tuned agents using ReAct-style trajectories with tool use

The common pattern: **the training data is structured interaction traces** — sequences of (observation, thought, action, tool_call, tool_result) tuples.

## 3. Analysis: A #B4mad-Tuned Agent Model

### 3.1 Target Capabilities

A #B4mad-tuned model needs three core capabilities:

**1. MCP Tool Calling:** Structured JSON tool invocations following the Model Context Protocol schema. The model must generate valid tool call JSON, handle tool results, and chain multiple tool calls.

**2. Beads Task Coordination:** Understanding bead lifecycle (create → assign → progress → close), parsing bead IDs, updating status, and reasoning about task dependencies and priorities.

**3. Multi-Agent Delegation:** Knowing when to delegate vs. handle directly, formulating clear sub-agent task descriptions, and synthesizing results from delegated work.

### 3.2 Dataset Strategy

This is the hard part. We need high-quality training data in three forms:

**A. Synthetic Trajectories from Existing Agents**
- Instrument our current Claude-powered agents to log full interaction traces
- Each trace: system prompt → user message → tool calls → results → response
- Estimated: 500-2000 high-quality traces needed for meaningful fine-tuning
- Timeline: 2-4 weeks of normal operation with logging enabled

**B. Curated Tool-Use Examples**
- Hand-craft 100-200 gold-standard examples of each pattern:
  - MCP tool call generation and result parsing
  - Bead creation, querying, updating, closing
  - Sub-agent task formulation and result synthesis
- These serve as the quality anchor for the dataset

**C. Rejection Sampling / DPO Pairs**
- Run the base model on #B4mad tasks, collect both successful and failed completions
- Use these as preference pairs for Direct Preference Optimization (DPO)
- This teaches the model our specific quality bar

### 3.3 Recommended Training Pipeline

```
Phase 1: SFT (Supervised Fine-Tuning)
  Base: Qwen3-8B (or Qwen3-30B-A3B for production)
  Method: QLoRA (4-bit base + LoRA rank 32)
  Data: 1000-2000 curated interaction traces
  Hardware: RTX 4090 (24GB) — sufficient for QLoRA on 8B
  Framework: Unsloth or Axolotl + HuggingFace PEFT
  Training time: ~4-8 hours for 8B, ~12-24 hours for 30B-A3B

Phase 2: DPO (Direct Preference Optimization)
  Data: 500+ preference pairs from rejection sampling
  Method: QLoRA DPO on Phase 1 checkpoint
  Training time: ~2-4 hours

Phase 3: Evaluation & Iteration
  Benchmarks: Custom #B4mad agent eval suite
  - Tool call accuracy (valid JSON, correct tool selection)
  - Bead lifecycle completion rate
  - Delegation appropriateness scoring
  - End-to-end task success on held-out beads
```

### 3.4 Hardware Feasibility

Our RTX 4090 (24GB VRAM) is well-suited for QLoRA fine-tuning:

| Model | QLoRA VRAM | Feasible? | Inference VRAM (4-bit) |
|-------|-----------|-----------|----------------------|
| Qwen3-4B | ~8GB | ✅ Easy | ~3GB |
| Qwen3-8B | ~14GB | ✅ Comfortable | ~6GB |
| Qwen3-14B | ~20GB | ✅ Tight | ~9GB |
| Qwen3-30B-A3B | ~16GB* | ✅ Good (MoE) | ~10GB* |
| Qwen3-32B | ~28GB | ❌ Too large | ~18GB |

*MoE models only load active experts, making the 30B-A3B surprisingly efficient.

The sweet spot for #B4mad is **Qwen3-8B for development/testing** and **Qwen3-30B-A3B for production**, both trainable on our single RTX 4090.

### 3.5 Risks and Limitations

1. **Catastrophic forgetting:** Fine-tuning on narrow agent tasks may degrade general capabilities. Mitigation: LoRA's parameter isolation naturally preserves base model knowledge; also mix in general instruction data during SFT.

2. **Dataset quality:** Garbage in, garbage out. Our biggest risk is insufficient or low-quality training data. Mitigation: Start with curated gold examples, expand gradually.

3. **Evaluation difficulty:** Agent task success is hard to measure automatically. Mitigation: Build a structured eval suite before training, not after.

4. **Maintenance burden:** Models need retraining as our tool schemas and agent patterns evolve. Mitigation: Keep training pipelines automated and modular.

5. **Capability ceiling:** A fine-tuned 8B model won't match Claude Opus on complex reasoning. Mitigation: Use the fine-tuned model for routine agent tasks; escalate to frontier models for complex reasoning.

## 4. Recommendations

### Immediate (Week 1-2)
1. **Instrument agent logging:** Add structured trace collection to all #B4mad agents (Brenner, PLTops, Lotti, Romanov). Every tool call, every bead operation, every delegation — logged as training data.
2. **Define eval suite:** Create 50+ test cases covering MCP tool calling, bead operations, and delegation scenarios. This is the yardstick before any training begins.

### Short-term (Week 3-6)
3. **Curate gold dataset:** Hand-craft 200 gold-standard examples. Run Qwen3-8B base on these tasks to establish baseline performance.
4. **First QLoRA training run:** Fine-tune Qwen3-8B on the curated dataset using Unsloth + PEFT. Evaluate against the test suite. This is the proof-of-concept.

### Medium-term (Month 2-3)
5. **Scale to Qwen3-30B-A3B:** Once the pipeline is validated on 8B, move to the MoE model for production-quality results.
6. **DPO pass:** Collect preference data from real agent runs, apply DPO for quality refinement.
7. **A/B test in production:** Run the fine-tuned model alongside Claude for a subset of routine tasks. Measure success rates, latency, and cost.

### Strategic
8. **Hybrid architecture:** Use the #B4mad-tuned model for 80% of routine agent operations (tool calling, bead management, simple delegation) and frontier models for the remaining 20% (complex reasoning, novel tasks). This could cut API costs by 80%+ while maintaining quality.

## 5. Conclusion

A #B4mad-tuned agent model is feasible, valuable, and achievable with our current hardware. The Qwen3 family — particularly the 8B dense and 30B-A3B MoE models — provides an excellent foundation. QLoRA makes training practical on a single RTX 4090.

The critical path is **not compute but data**: instrumenting our agents to collect high-quality interaction traces, curating gold-standard examples, and building a rigorous evaluation suite. With 4-6 weeks of focused effort, we could have a proof-of-concept model that handles routine agent tasks locally, reducing our dependence on frontier API providers and advancing #B4mad's mission of technological sovereignty.

The question isn't whether we *can* build a #B4mad-tuned model. It's whether we have the discipline to collect great training data first.

## References

1. Dettmers, T., Pagnoni, A., Holtzman, A., & Zettlemoyer, L. (2023). "QLoRA: Efficient Finetuning of Quantized LLMs." arXiv:2305.14314.
2. Hu, E.J., et al. (2021). "LoRA: Low-Rank Adaptation of Large Language Models." arXiv:2106.09685.
3. Qwen Team (2025). "Qwen3: Think Deeper, Act Faster." https://qwenlm.github.io/blog/qwen3/
4. Patil, S., et al. (2023). "Gorilla: Large Language Model Connected with Massive APIs." arXiv:2305.15334.
5. Qin, Y., et al. (2023). "ToolLLM: Facilitating Large Language Models to Master 16000+ Real-world APIs." arXiv:2307.16789.
6. Zeng, A., et al. (2023). "AgentTuning: Enabling Generalized Agent Abilities for LLMs." arXiv:2310.12823.
7. Chen, B., et al. (2023). "FireAct: Toward Language Agent Fine-tuning." arXiv:2310.05915.
8. HuggingFace PEFT Library. https://github.com/huggingface/peft
9. Fridman, L. (2026). "State of AI in 2026" Podcast #490, with Sebastian Raschka & Nathan Lambert. https://lexfridman.com/ai-sota-2026-transcript
10. Raschka, S. (2025). "Build a Large Language Model from Scratch." Manning Publications.
