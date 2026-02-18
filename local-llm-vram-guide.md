# Local LLM VRAM Guide: Fitting Models on Consumer GPUs

> Written by PltOps @ #B4mad Industries — February 2026
> Context: Investigation of inference timeouts on our local Ollama setup (bead `beads-hub-b4u`)

## TL;DR

An 80B dense model needs ~51GB VRAM. Our RTX 4090 has 24GB. The overflow spilled to CPU RAM, causing crippling timeouts. We switched to a **Mixture-of-Experts (MoE)** model (`qwen3-coder:30b-a3b-q4_K_M`) that fits in 18GB and activates only ~3B parameters per token. Problem solved.

---

## Our GPU Setup

| Component | Spec |
|-----------|------|
| GPU | NVIDIA RTX 4090 |
| VRAM | 24 GB GDDR6X |
| Host RAM | 128 GB DDR5 |
| Inference server | Ollama |
| OS | Linux (WSL2) |

## Why the 80B Model Failed

### The Math

For a dense transformer model with Q4 quantization:

```
VRAM ≈ (params × bits_per_param) / 8 + KV_cache + overhead

80B × 4 bits / 8 = 40 GB  (weights alone)
+ KV cache (~8GB at 8K context) = ~48 GB
+ CUDA overhead (~3 GB) = ~51 GB total
```

Our 24GB card can hold ~22GB of model weights (after reserving for KV cache and overhead). That means **~58% of the model stays in VRAM**, and the remaining **~42% spills to system RAM**.

### What CPU Spillover Looks Like

When a model partially offloads to CPU:
- Each forward pass shuttles tensors across the PCIe bus (16 GB/s vs 1 TB/s GPU memory bandwidth)
- Inference slows by **10-50×** for the offloaded layers
- Ollama's default timeout fires → request fails
- The GPU sits partially idle waiting for CPU layers to complete

This is exactly what we observed: intermittent timeouts, high CPU usage during inference, and GPU utilization never hitting 100%.

## The Investigation

### Options Considered

| Option | VRAM Needed | Trade-off |
|--------|-------------|-----------|
| 80B Q4_K_M (original) | ~51 GB | Way too large |
| 80B Q2_K | ~25 GB | Fits barely, severe quality loss |
| 70B Q3_K_S | ~30 GB | Still too large |
| 32B Q4_K_M (dense) | ~20 GB | Fits, but fewer params = less capability |
| **30B MoE Q4_K_M** | **~18 GB** | **Fits with headroom, 30.5B total / ~3B active** |

### Why We Didn't Just Use a Smaller Dense Model

A dense 32B model activates all 32B parameters for every token. A 30B MoE model has 30.5B total parameters but routes each token through only ~3B of them (the "active" experts). This means:

- **Knowledge capacity** comparable to a much larger model (experts specialize)
- **Inference cost** comparable to a 3B model (only active params compute)
- Best of both worlds for VRAM-constrained setups

## Why MoE Wins for Constrained VRAM

### How Mixture-of-Experts Works

```
Input Token
    ↓
┌─────────┐
│  Router  │  ← Learned gating network
└─────────┘
    ↓ selects top-k experts (typically 2)
┌──────┬──────┬──────┬──────┐
│ Exp1 │ Exp2 │ Exp3 │ ... │  ← Only selected experts compute
└──────┴──────┴──────┴──────┘
    ↓ weighted sum
  Output
```

- **All expert weights live in VRAM** (you pay full storage cost)
- **Only 2 experts run per token** (you pay minimal compute cost)
- Result: big model knowledge, small model speed

### The Key Insight

VRAM stores the full model, but **compute scales with active parameters**. For a 30B MoE with ~3B active:
- Storage: 18 GB (all experts in VRAM)
- Compute per token: equivalent to a ~3B dense model
- Tokens/second: fast (limited by the ~3B active path, not 30B)

## Our Final Configuration

```yaml
Model: qwen3-coder:30b-a3b-q4_K_M
Total params: 30.5B
Active params per token: ~3B
Quantization: Q4_K_M (4-bit, k-quant mixed)
VRAM usage: ~18 GB
Remaining VRAM: ~6 GB (KV cache + overhead)
Context window: 8K default (expandable with VRAM headroom)
```

### VRAM Budget Breakdown

```
Total VRAM:          24.0 GB
─────────────────────────────
Model weights:       15.5 GB  (30.5B × 4 bits / 8, compressed)
KV cache (8K ctx):    1.5 GB
CUDA context:         0.8 GB
Ollama overhead:      0.2 GB
─────────────────────────────
Used:               ~18.0 GB
Free:                ~6.0 GB  ← buffer for longer contexts
```

## How to Check Your Own Setup

### 1. Check Available VRAM

```bash
nvidia-smi
# Look for "MiB" columns — total and used
```

### 2. Check Model Size Before Pulling

```bash
# See model details on ollama.com or:
ollama show <model> --modelfile
# Look for the parameter count and quantization
```

### 3. Estimate VRAM Requirement

```bash
# Quick formula for Q4 quantization:
# VRAM (GB) ≈ params_in_billions × 0.5 + 2 (overhead)
# Examples:
#   7B  → ~5.5 GB
#   13B → ~8.5 GB
#   30B → ~17 GB
#   70B → ~37 GB
```

### 4. Monitor During Inference

```bash
# Watch GPU usage in real-time:
watch -n 1 nvidia-smi

# Check if Ollama is offloading to CPU:
# Look for "offloading X layers to CPU" in Ollama logs
journalctl -u ollama -f
# or
ollama logs
```

### 5. Check Layer Offloading

If `nvidia-smi` shows VRAM maxed out and CPU usage is high during inference, layers are being offloaded. This is the #1 cause of slow local LLM performance.

## Future Considerations

- **RTX 5090 (32GB)**: Would allow larger MoE models or dense 32B at full context
- **Multi-GPU**: Ollama doesn't natively split across GPUs well; vLLM or llama.cpp can
- **Better quantizations**: As Q4_K_M evolves (GGUF improvements), quality per bit improves
- **Longer context**: Our 6GB headroom allows ~16K context; for 32K+ we'd need a smaller model or more VRAM
- **VRAM-efficient attention**: Flash Attention and paged KV cache (vLLM) reduce KV cache footprint

---

## References

- [Ollama documentation](https://ollama.com)
- [GGUF quantization formats](https://github.com/ggerganov/llama.cpp/blob/master/README.md)
- [Qwen3 model card](https://huggingface.co/Qwen)
- GitHub issue: [brenner-axiom/beads-hub#26](https://github.com/brenner-axiom/beads-hub/issues/26)
