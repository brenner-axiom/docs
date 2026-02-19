# LOOPY Agent Network Dynamics Model for #B4mad Industries

**Author:** Roman "Romanov" Research-Rachmaninov
**Date:** 2026-02-19
**Bead:** beads-hub-eaf
**Status:** Published
**Companion to:** [LOOPY Sustainability Model](2026-02-19-loopy-sustainability-model.md)

## Abstract

This paper presents a causal loop model of #B4mad's multi-agent operations, designed for implementation in LOOPY (ncase.me/loopy). Where the companion sustainability model examines economic viability, this model focuses inward: how agent spawning, bead-driven task coordination, and trust dynamics create feedback loops that govern operational throughput and quality. We identify three reinforcing loops (the trust flywheel, the skill accumulation engine, and the throughput amplifier) and two balancing loops (context overhead and coordination cost). The complete node-edge specification enables direct recreation as an interactive LOOPY simulation.

## Context: Why Agent Dynamics Matter

#B4mad runs a hierarchical multi-agent system: a main agent orchestrates specialized sub-agents (CodeMonkey, PltOps, Romanov, Brew) via the Beads task coordination protocol. This architecture raises systems-level questions that spreadsheets and intuition handle poorly:

- Does spawning more sub-agents always increase throughput, or is there a saturation point?
- What feedback loops exist between bead creation rate, agent workload, and completion quality?
- How does the reinforcing loop of *better agents → more trust → more autonomy → better agents* actually behave?

Causal loop diagrams make these dynamics visible and testable.

## The LOOPY Model

### Nodes (Variables)

The model uses 11 nodes representing key state variables of the agent network:

| # | Node | Description |
|---|------|-------------|
| 1 | **Sub-Agent Count** | Number of active sub-agents spawned |
| 2 | **Throughput** | Beads completed per unit time |
| 3 | **Agent Skill** | Accumulated quality of agent prompts, tools, and patterns |
| 4 | **Trust Level** | Human operator's trust in agent autonomy |
| 5 | **Autonomy Granted** | Scope of tasks delegated without human review |
| 6 | **Bead Creation Rate** | New beads (tasks) entering the system |
| 7 | **Bead Backlog** | Unfinished beads awaiting work |
| 8 | **Coordination Overhead** | Time spent on inter-agent sync, context passing, conflict resolution |
| 9 | **Context Window Pressure** | Token/memory consumption per agent session |
| 10 | **Error Rate** | Failed or low-quality task completions |
| 11 | **Completion Quality** | Overall quality of delivered work |

### Edges (Causal Links)

| From | To | Polarity | Rationale |
|------|----|----------|-----------|
| Sub-Agent Count | Throughput | + | More agents process more beads in parallel |
| Sub-Agent Count | Coordination Overhead | + | More agents require more synchronization |
| Coordination Overhead | Throughput | − | Coordination time displaces productive work |
| Coordination Overhead | Error Rate | + | Complex handoffs introduce miscommunication |
| Throughput | Bead Backlog | − | Higher throughput drains the backlog |
| Bead Creation Rate | Bead Backlog | + | New tasks accumulate |
| Bead Backlog | Sub-Agent Count | + | Growing backlog triggers more agent spawning |
| Agent Skill | Completion Quality | + | Better-trained agents produce higher quality |
| Agent Skill | Error Rate | − | Skilled agents make fewer mistakes |
| Completion Quality | Trust Level | + | Consistent quality builds human trust |
| Error Rate | Trust Level | − | Errors erode trust |
| Trust Level | Autonomy Granted | + | Trust enables delegation |
| Autonomy Granted | Bead Creation Rate | + | Autonomous agents generate sub-tasks proactively |
| Autonomy Granted | Agent Skill | + | Autonomy provides learning opportunities (practice → improvement) |
| Completion Quality | Agent Skill | + | Successful patterns get codified (AGENTS.md, SKILL.md updates) |
| Sub-Agent Count | Context Window Pressure | + | Each agent consumes context tokens |
| Context Window Pressure | Completion Quality | − | Constrained context degrades output quality |
| Error Rate | Autonomy Granted | − | Errors trigger tighter human oversight |

### Feedback Loops Identified

#### Reinforcing Loops (Growth Engines) 🔄↑

**R1 — The Trust Flywheel** (the core virtuous cycle):
> Agent Skill → Completion Quality → Trust Level → Autonomy Granted → Agent Skill

This is the central claim of agent-first operations: better agents earn trust, trust grants autonomy, autonomy accelerates learning, learning produces better agents. This loop explains why investing in agent infrastructure (better prompts, better tools, better memory) has compounding returns.

**Key insight:** The loop has a *cold start* problem. Initial trust must be manually bootstrapped (careful human review of early outputs). Once the flywheel spins, it's self-sustaining.

**R2 — The Throughput Amplifier:**
> Bead Backlog → Sub-Agent Count → Throughput → Bead Backlog (−)

A demand-driven scaling loop. As backlog grows, more agents spawn, increasing throughput, which reduces backlog. This is a *goal-seeking* loop that stabilizes around the bead creation rate — but only if coordination overhead doesn't dominate (see B1).

**R3 — The Skill Accumulation Engine:**
> Autonomy Granted → Bead Creation Rate → Bead Backlog → Sub-Agent Count → Throughput → (more completed work) → Completion Quality → Agent Skill → (via R1) → Autonomy Granted

A longer reinforcing path: more autonomy creates more tasks, which creates more practice, which builds more skill. This loop explains why mature agent systems accelerate over time — they generate their own training data through operational experience.

#### Balancing Loops (Governors) ⚖️

**B1 — The Coordination Ceiling:**
> Sub-Agent Count → Coordination Overhead → Throughput (−) → Bead Backlog (remains high) → Sub-Agent Count (spawns more)

This is the critical failure mode. Naively spawning more agents increases coordination overhead faster than throughput, creating a vicious cycle where more agents make things *worse*. This is Brooks's Law applied to agents: adding agents to a late backlog makes it later.

**Escape hatch:** Reduce coordination overhead through better protocols (Beads), clearer agent specialization, and shared memory (workspace files). The bead system exists precisely to break this loop.

**B2 — The Context Crunch:**
> Sub-Agent Count → Context Window Pressure → Completion Quality (−) → Trust Level (−) → Autonomy Granted (−) → Bead Creation Rate (−) → fewer agents needed

As agents proliferate, context windows fill up. Quality drops, trust drops, autonomy contracts, and the system self-corrects by reducing demand. This is a natural governor — but a painful one. Better to manage context proactively (compact histories, focused sub-agent scopes) than to hit this wall.

**B3 — The Error Brake:**
> Error Rate → Trust Level (−) → Autonomy Granted (−) → (fewer proactive tasks) → Bead Creation Rate (−)

Errors directly reduce autonomy. This is a healthy safety mechanism — the system self-corrects when quality drops. But if error rate spikes (model regression, bad prompt update), the brake can be too aggressive, stalling the entire operation.

### Key Dynamics and Insights

#### 1. The Optimal Agent Count Is Not "More"

R2 and B1 interact to create an **inverted-U relationship** between sub-agent count and throughput. Below the optimum, adding agents helps. Above it, coordination overhead dominates. For #B4mad's current architecture (main + 4 specialists), the coordination cost is low because agents are highly specialized with minimal overlap. Scaling to 10+ generalist agents would likely hit B1 hard.

#### 2. Trust Is the Master Variable

Trust Level influences everything downstream. It gates autonomy, which gates bead creation, which gates throughput. A single high-profile failure (bad commit, wrong email sent, data leak) can crash trust and stall the entire system. This argues for conservative safety defaults — the compound cost of a trust collapse far exceeds the marginal throughput from looser controls.

#### 3. The Bead System Breaks Brooks's Law

Traditional multi-agent coordination suffers from O(n²) communication overhead. The Beads system linearizes this by providing structured, asynchronous task handoff. Each agent reads its bead, does the work, closes the bead. No chat, no negotiation, no meetings. This is why B1 doesn't dominate in the current architecture.

#### 4. Skill Accumulation Requires Codification

R1 only works if skill improvements are *persisted* — written to AGENTS.md, SKILL.md, MEMORY.md. Without codification, each new agent session starts from zero. The workspace-as-memory architecture is the mechanism that converts ephemeral learning into durable skill.

#### 5. Context Window Pressure Is the Binding Constraint

B2 is currently the most active balancing loop. Agent sessions hit context limits, quality degrades, and humans must intervene. Mitigations: smaller focused sub-agents (Brew for URLs, CodeMonkey for code), aggressive context compaction, and model improvements over time.

## Comparison with the Sustainability Model

The [sustainability model](2026-02-19-loopy-sustainability-model.md) examines #B4mad's economic dynamics (donations, compute costs, community growth). This agent dynamics model examines operational dynamics. The two models connect at key interfaces:

| Sustainability Node | Agent Dynamics Node | Connection |
|--------------------|--------------------|------------|
| Agent Capability | Agent Skill | Same concept, different granularity |
| Platform Quality | Completion Quality | Agent output quality drives platform quality |
| Compute Cost | Sub-Agent Count | More agents consume more compute |
| Community Size | Trust Level | Community trust emerges from consistent quality |

A combined model would show how operational excellence (this model) feeds economic sustainability (companion model) and vice versa.

## Recreating the Model in LOOPY

To build this in LOOPY (ncase.me/loopy):

1. Create 11 nodes arranged in a rough circle, labeled as in the node table
2. Add edges with polarities as specified in the edge table
3. Suggested layout: Trust Level and Agent Skill at top center (the core flywheel), Sub-Agent Count and Throughput at left (the scaling loop), Bead Backlog and Bead Creation Rate at bottom (the demand side), Coordination Overhead and Context Window Pressure at right (the constraints)
4. Initialize Trust Level at medium, Agent Skill at medium, Sub-Agent Count at low
5. Perturb by increasing Bead Creation Rate and observe the system response

## Recommendations

1. **Keep specialist agents, avoid generalists.** Specialization minimizes coordination overhead (B1) and context pressure (B2).
2. **Invest in trust-building.** Conservative safety defaults, mandatory human review for high-stakes actions. The trust flywheel (R1) is the most valuable loop to protect.
3. **Codify everything.** Every lesson, every pattern, every failure. R1 and R3 depend on persistent memory.
4. **Monitor context window usage.** B2 is the binding constraint today. Track it, optimize for it.
5. **Use Beads religiously.** The structured task protocol is what keeps B1 from dominating as the fleet grows.

## References

- Nicky Case, "LOOPY: A tool for thinking in systems," ncase.me/loopy (CC0 Public Domain)
- Frederick Brooks, *The Mythical Man-Month* (1975) — Brooks's Law on adding personnel
- Peter Senge, *The Fifth Discipline* (1990) — Systems thinking and organizational learning
- Donella Meadows, *Thinking in Systems* (2008) — Leverage points in complex systems
- Romanov, "LOOPY Sustainability Model for #B4mad Industries" (2026-02-19) — Companion paper
- Steve Yegge, "Beads: A task coordination protocol" — github.com/steveyegge/beads
