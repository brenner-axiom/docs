---
layout: page
title: "Benchmarking Agent-Generated Code Quality: A #B4mad Framework"
---

# Benchmarking Agent-Generated Code Quality: A #B4mad Framework

**Author:** Roman "Romanov" Research-Rachmaninov, #B4mad Industries  
**Date:** 2026-02-20  
**Bead:** beads-hub-3qz

## Abstract

As AI coding agents move from toy demos to production workflows, the benchmarks we use to evaluate them haven't kept up. HumanEval measures whether an agent can write a single function; real work means orchestrating multi-file changes, using tools, iterating on review feedback, and shipping code that passes CI. This paper surveys existing code generation benchmarks, identifies critical gaps for agent-driven development, and proposes **BeadBench** — a benchmark concept grounded in #B4mad's bead-driven development workflow that measures what actually matters: does the code ship, and does it hold up?

## 1. Context: Why This Matters for #B4mad

#B4mad Industries operates an agent-first development pipeline where AI agents (CodeMonkey, PltOps, Romanov) handle the majority of code production, tracked through the Beads task system. Every bead represents a real work unit — from creation through implementation, review, merge, and deployment.

This gives us something most benchmark creators don't have: **ground truth on the full lifecycle of agent-generated code in production**. We're not measuring whether an agent *can* code; we're measuring whether agent code *ships and survives*.

## 2. State of the Art: Existing Benchmarks

### 2.1 Function-Level Benchmarks

**HumanEval** (Chen et al., 2021): 164 hand-written Python problems with unit tests. The benchmark that launched a thousand leaderboards. Pass@1 scores now exceed 90% for frontier models, effectively saturating the benchmark. Measures: single-function correctness.

**MBPP** (Austin et al., 2021): 974 crowd-sourced Python problems. Broader than HumanEval but still single-function, single-file. Most problems solvable in <20 lines.

**HumanEval+/EvalPlus** (Liu et al., 2023): Augments HumanEval with 80× more tests per problem, catching solutions that pass original tests but are actually wrong. Important contribution — exposed how many "correct" solutions were overfitting to weak test suites.

**LiveCodeBench** (Jain et al., 2024): Continuously updated from competitive programming platforms to prevent contamination. Good for tracking progress over time but still algorithmic puzzle-solving.

### 2.2 Repository-Level Benchmarks

**SWE-bench** (Jimenez et al., 2024): The current gold standard for realistic agent evaluation. 2,294 GitHub issues from 12 popular Python repositories, each requiring the agent to produce a patch that passes the repository's test suite. SWE-bench Verified narrows to 500 human-validated instances.

Key strengths: real codebases, real issues, real tests. Key limitations: Python-only, heavily weighted toward a few repos (django, sympy, scikit-learn), no multi-PR workflows, no iterative review.

**SWE-bench Multimodal** (Yang et al., 2024): Extends SWE-bench with issues containing images (screenshots, diagrams). Tests visual understanding alongside code generation.

**RepoBench** (Liu et al., 2023): Focuses on cross-file code completion within repositories. Tests retrieval of relevant context and code generation conditioned on multi-file understanding.

### 2.3 Agent-Specific Benchmarks

**WebArena / OSWorld** (Zhou et al., 2024; Xie et al., 2024): Evaluate agents operating in web/OS environments. Not code-generation-specific but relevant for tool-using agent evaluation.

**GAIA** (Mialon et al., 2023): General AI assistants benchmark requiring multi-step reasoning with tool use. Includes some coding tasks but is broader.

**Aider Polyglot Benchmark** (Gauthier, 2024): Tests code editing across multiple programming languages. Practical but limited to single-file edits guided by natural language instructions.

### 2.4 Summary Table

| Benchmark | Scope | Multi-file | Tool Use | Iterative | Real-world |
|---|---|---|---|---|---|
| HumanEval | Function | ❌ | ❌ | ❌ | ❌ |
| MBPP | Function | ❌ | ❌ | ❌ | ❌ |
| SWE-bench | Repository | ✅ | ❌ | ❌ | ✅ |
| RepoBench | Repository | ✅ | ❌ | ❌ | Partial |
| Aider Polyglot | File | ❌ | ❌ | ❌ | Partial |
| **BeadBench** (proposed) | Workflow | ✅ | ✅ | ✅ | ✅ |

## 3. Analysis: What's Missing

### 3.1 No Benchmark Tests the Full Agent Loop

Every existing benchmark treats code generation as a **one-shot** problem: given a prompt, produce code. But real agent workflows are iterative:

1. Agent reads a task description (bead)
2. Agent explores the codebase (tool use: grep, read, search)
3. Agent writes code across multiple files
4. CI runs; tests fail; agent reads errors and fixes
5. Human reviews; requests changes; agent addresses feedback
6. Code merges; deployment succeeds (or doesn't)

No benchmark captures steps 4–6. This is where most real-world quality problems live.

### 3.2 Tool Use Is Invisible

Agents don't just generate code — they read files, search codebases, run tests, check documentation. The *quality of tool use* (efficient retrieval, minimal unnecessary reads, correct test interpretation) is unmeasured. An agent that reads 200 files to make a 3-line change is wasteful even if the change is correct.

### 3.3 Security Is an Afterthought

No major benchmark systematically evaluates security properties of generated code. CyberSecEval (Meta, 2024) exists but is disconnected from code generation workflows. In production, agents that introduce SQL injection or hardcoded credentials are worse than agents that produce no code at all.

### 3.4 Human Review Cost Is Ignored

A benchmark might score an agent at 80% pass rate, but if the 80% "correct" solutions each require 30 minutes of human review to verify, the real productivity gain is minimal. Review burden is a first-class metric that no benchmark captures.

### 3.5 Longitudinal Quality Is Unmeasured

Does agent-generated code survive? Or does it create maintenance debt that humans clean up weeks later? No benchmark tracks code quality over time — reverts, hotfixes, refactoring of agent-written code.

## 4. Proposal: BeadBench — A #B4mad Benchmark Concept

### 4.1 Core Idea

BeadBench treats **beads as benchmark instances**. Each bead in our system represents a real task with:
- A natural language description
- A target repository and branch
- Acceptance criteria (explicit or implicit via tests)
- A full audit trail (commits, reviews, CI results, merge status)

By replaying historical beads against agents, we get a benchmark grounded in real production work — not synthetic puzzles.

### 4.2 Benchmark Structure

**Level 1 — Bead Resolution:** Given a bead description and repository state, produce a PR that passes CI. This is closest to SWE-bench but uses our real task descriptions and acceptance criteria.

**Level 2 — Review Survival:** The PR must also pass human review with ≤1 round of revision requests. Measures code quality beyond mere correctness.

**Level 3 — Production Survival:** Merged code must not be reverted, hotfixed, or substantially refactored within 30 days. Measures long-term code quality.

### 4.3 Proposed Metrics

| Metric | What It Measures | How to Compute |
|---|---|---|
| **Bead Resolution Rate** | Can the agent produce a working solution? | PRs that pass CI / total beads attempted |
| **First-Pass Merge Rate** | Does the code ship without review cycles? | PRs merged without revision / total PRs |
| **Review Cycle Count** | How much human effort to get to merge? | Average revision rounds per merged PR |
| **Time to Resolution** | Agent efficiency | Wall-clock time from bead assignment to merge |
| **Test Coverage Delta** | Does the agent write tests? | Coverage change introduced by the PR |
| **Security Score** | Does the agent introduce vulnerabilities? | Static analysis findings (Semgrep, Bandit) on the diff |
| **Token Efficiency** | Cost of the solution | Total tokens consumed per resolved bead |
| **Survival Rate** | Does the code hold up? | % of merged PRs not reverted/hotfixed within 30 days |
| **Tool Efficiency** | Smart use of context | Files read / files changed ratio; unnecessary API calls |

### 4.4 Dataset Construction

From our beads-hub history, we can extract benchmark instances:

```
{
  "bead_id": "beads-hub-abc",
  "title": "Fix pagination in API endpoint",
  "description": "The /api/v1/items endpoint returns all results...",
  "repo": "b4mad/api-server",
  "base_commit": "a1b2c3d",
  "ground_truth_patch": "diff --git a/...",
  "ci_result": "pass",
  "review_rounds": 1,
  "merged": true,
  "reverted": false
}
```

Each instance includes the repository state at the time of assignment, enabling reproducible evaluation.

### 4.5 Evaluation Protocol

1. **Snapshot** the repository at the bead's creation timestamp
2. **Present** the bead description to the agent
3. **Allow** full tool use (file read, search, test execution, web lookup)
4. **Collect** the generated PR (diff + commit messages)
5. **Run CI** against the repository's test suite
6. **Score** using the metrics above
7. **Optionally** run human review for Level 2 evaluation

### 4.6 Anti-Contamination

Since beads are continuously created, the benchmark naturally refreshes. We propose:
- **Static set:** 50 historical beads for consistent comparison (versioned, never updated)
- **Rolling set:** Last 30 days of closed beads, re-evaluated monthly
- **Live set:** Currently open beads, for real-time agent evaluation (this is just... using the agent)

## 5. Recommendations

1. **Start collecting bead metadata now.** Every bead should record: time-to-resolution, review rounds, CI pass/fail, revert status, token cost. This is the training data for BeadBench.

2. **Instrument CodeMonkey.** Add structured logging for tool use patterns, token consumption per bead, and revision cycles. This data feeds directly into benchmark metrics.

3. **Build a minimal BeadBench prototype.** Start with 20 historical beads that have clean ground-truth patches. Evaluate CodeMonkey against them. Publish internal results.

4. **Integrate security scanning.** Run Semgrep/Bandit on every agent-generated diff. Track the security score metric from day one.

5. **Publish the benchmark.** Once we have 50+ validated instances, open-source BeadBench. The agent-first development community needs a benchmark that goes beyond single-function puzzles. We have the data to build it.

6. **Track survival rate.** Set up a 30-day post-merge monitoring pipeline. This is the metric that will differentiate BeadBench from everything else — nobody else measures whether generated code actually holds up.

## 6. References

- Austin, J., et al. (2021). "Program Synthesis with Large Language Models." arXiv:2108.07732.
- Chen, M., et al. (2021). "Evaluating Large Language Models Trained on Code." arXiv:2107.03374.
- Gauthier, P. (2024). "Aider Polyglot Benchmark." aider.chat/docs/leaderboards.
- Jain, N., et al. (2024). "LiveCodeBench: Holistic and Contamination Free Evaluation of Large Language Models for Code." arXiv:2403.07974.
- Jimenez, C.E., et al. (2024). "SWE-bench: Can Language Models Resolve Real-World GitHub Issues?" arXiv:2310.06770.
- Liu, J., et al. (2023). "Is Your Code Generated by ChatGPT Really Correct? Rigorous Evaluation of Large Language Models for Code Generation." NeurIPS 2023.
- Liu, T., et al. (2023). "RepoBench: Benchmarking Repository-Level Code Auto-Completion Systems." arXiv:2306.03091.
- Meta (2024). "CyberSecEval: A Comprehensive Benchmark for Evaluating Cybersecurity Risks of LLMs."
- Mialon, G., et al. (2023). "GAIA: A Benchmark for General AI Assistants." arXiv:2311.12983.
- Xie, T., et al. (2024). "OSWorld: Benchmarking Multimodal Agents for Open-Ended Tasks in Real Computer Environments." arXiv:2404.07972.
- Yang, J., et al. (2024). "SWE-bench Multimodal." Princeton NLP.
- Zhou, S., et al. (2024). "WebArena: A Realistic Web Environment for Building Autonomous Agents." arXiv:2307.13854.

---

*Published as part of the #B4mad Research Pipeline. Bead: beads-hub-3qz.*
