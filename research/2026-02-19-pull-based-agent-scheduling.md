# Pull-Based Agent Scheduling Architecture for #B4mad

**Author:** Roman "Romanov" Research-Rachmaninov  
**Date:** 2026-02-19  
**Bead:** beads-hub-30f  
**Status:** Final

## Abstract

This paper proposes a pull-based task scheduling architecture for the #B4mad agent fleet (Brenner Axiom, PltOps, CodeMonkey, Romanov). The current push model—where Brenner Axiom centrally dispatches work to specialist agents—creates a single point of failure and limits agent autonomy. We analyze scheduling patterns from distributed systems (Kubernetes, GitOps, actor models) and multi-agent frameworks (CrewAI, AutoGen), then recommend a hybrid pull/pub-sub architecture using git-backed beads as the shared work queue with optimistic locking for conflict resolution.

## 1. Context: Why This Matters for #B4mad

Today, Brenner Axiom reads every incoming message, decides which specialist handles it, and spawns sub-agents on demand. This works but has clear limitations:

- **Central bottleneck**: If Brenner is busy or down, no work gets dispatched.
- **No agent autonomy**: Specialists cannot self-select work they're best suited for.
- **No backpressure**: Brenner has no visibility into agent capacity.
- **Wasted heartbeats**: Agents wake up on cron, check nothing specific, and go back to sleep.

The vision: each specialist agent has its own persistent heartbeat, autonomously polls the bead board for work matching its skillset, claims tasks, and executes them—without Brenner as intermediary.

## 2. Scheduling Patterns in Multi-Agent and Distributed Systems

### 2.1 Push-Based (Current Model)

A central dispatcher assigns work to workers. Examples: traditional job schedulers (Slurm), CrewAI's sequential/hierarchical process, Brenner Axiom today.

**Pros:** Simple coordination, clear ownership, predictable ordering.  
**Cons:** Single point of failure, dispatcher must know worker capacity, poor scalability.

### 2.2 Pull-Based (Work Stealing)

Workers poll a shared queue and claim tasks. Examples: Kubernetes scheduler (nodes don't pull, but pods are scheduled based on declared capacity), GitOps (Flux/ArgoCD pull from git), Go's goroutine work-stealing scheduler.

**Pros:** Workers self-regulate, natural load balancing, no central bottleneck for dispatch.  
**Cons:** Conflict resolution needed (two workers grab same task), polling overhead, potential starvation.

### 2.3 Pub/Sub (Event-Driven)

Workers subscribe to task topics and receive notifications. Examples: NATS, Redis Streams, Kafka consumer groups, Erlang/OTP message passing.

**Pros:** Low latency, no polling waste, natural filtering by topic.  
**Cons:** Requires persistent messaging infrastructure, more complex failure handling, ordering guarantees vary.

### 2.4 Actor Model (Erlang/Akka)

Each agent is an actor with a mailbox. Messages are routed to actors based on type. Supervision trees handle failures.

**Pros:** Fault isolation, location transparency, proven at scale (telecom, gaming).  
**Cons:** Requires an actor runtime, message ordering is per-pair only, complex to debug.

### 2.5 Hybrid: Pull + Notification

Workers primarily pull, but a lightweight notification layer (webhook, file watch, pub/sub) wakes them when new work appears. This combines pull's simplicity with pub/sub's responsiveness.

**This is our recommended approach.**

## 3. Comparison with Existing Systems

| System | Model | Conflict Resolution | Capacity Signaling | Relevance |
|--------|-------|--------------------|--------------------|-----------|
| **Kubernetes Scheduler** | Push (scheduler assigns pods to nodes) | Scheduler is single decision-maker | Node resource declarations (allocatable CPU/mem) | Inspiration for capacity model |
| **GitOps (Flux/ArgoCD)** | Pull (controllers poll git for desired state) | Git is single source of truth; last-write-wins | Controllers reconcile continuously | Direct analogy—beads repo IS our gitops source |
| **Erlang/OTP** | Actor (message passing with mailboxes) | No shared state; each actor owns its data | Mailbox depth as backpressure signal | Inspiration for agent isolation |
| **CrewAI** | Push (crew orchestrator assigns tasks to agents) | Sequential or hierarchical process prevents conflicts | No explicit capacity model | Current model equivalent |
| **AutoGen** | Push/conversational (agents converse to coordinate) | Conversation-based negotiation | No explicit model | Too chatty for our use case |

### Key Insight: GitOps Is Our Closest Analog

The beads-hub repo already functions as a GitOps-style desired-state store. Beads are YAML files in git. The transition from push to pull is natural:

- **Current:** Brenner reads bead → spawns specialist
- **Proposed:** Specialist polls bead board → claims matching bead → executes

## 4. Conflict Resolution: Claiming Beads

**Problem:** Two agents poll simultaneously, both see the same unclaimed bead, both try to claim it.

### Recommended: Optimistic Locking via Git

1. Agent pulls latest bead board (`git pull`)
2. Agent updates bead status to `in_progress` with its agent ID as owner
3. Agent commits and pushes
4. **If push fails** (another agent pushed first) → `git pull --rebase`, check if bead was already claimed → if so, skip; if not, retry
5. **If push succeeds** → agent owns the bead

This is essentially optimistic concurrency control using git's built-in conflict detection. It works because:

- Git push is atomic per-ref
- Bead files are small YAML; merge conflicts are obvious
- Our agent fleet is small (3-5 agents); contention is rare

### Alternative Considered: Distributed Locks

Using Redis or etcd for distributed locking was considered but rejected—it adds infrastructure complexity disproportionate to our fleet size. Git-based optimistic locking is sufficient for <10 agents.

### Claim Protocol

```
bd claim <bead-id> --agent <agent-name>
```

This would:
1. Set `status: in_progress`
2. Set `owner: <agent-name>@b4mad`
3. Add `claimed_at: <timestamp>`
4. Commit and push (with retry on conflict)

## 5. Polling Intervals by Agent Type

Polling interval should balance responsiveness against resource cost (API calls, git operations, token consumption).

| Agent | Role | Recommended Interval | Rationale |
|-------|------|---------------------|-----------|
| **PltOps** | Infrastructure/SRE | 15 min | Infra tasks are rarely urgent; batch is fine |
| **CodeMonkey** | Coding | 30 min | Code tasks benefit from batching; PRs don't need instant pickup |
| **Romanov** | Research | 60 min | Research is inherently slow; hourly check is plenty |
| **Brenner (main)** | Coordinator | 15 min (heartbeat) | Still handles interactive messages; heartbeat catches stragglers |

### Adaptive Polling

Agents should adjust intervals based on queue depth:
- **Queue empty for 3 cycles** → double interval (up to max 2h)
- **Queue has items** → reset to base interval
- **Agent just completed a task** → immediate re-poll (grab next task while warm)

## 6. Capacity and Overload Signaling

### Agent Capacity Model

Each agent maintains a simple capacity file or bead metadata:

```yaml
# .agent-status/codemonkey.yaml
agent: codemonkey
status: available | busy | overloaded | offline
current_tasks: 1
max_concurrent: 2
last_heartbeat: 2026-02-19T21:00:00Z
```

**Rules:**
- `available`: Will claim new beads matching skillset
- `busy`: At max_concurrent; skip this polling cycle
- `overloaded`: Has failed or stalled tasks; needs attention
- `offline`: Agent cron is disabled or agent is in maintenance

### Backpressure Mechanism

1. Agent checks own capacity before polling
2. If `busy`, agent skips claim phase but still reports heartbeat
3. If a bead has been `in_progress` for >2× expected duration, Brenner (or any agent) can flag it as stalled
4. Stalled beads get reassigned (owner cleared, status back to `ready`)

## 7. Pub/Sub vs Polling: Can We Do Better?

### Pure Polling (Git-Based)

**Implementation:** Cron job → `git pull` → `bd ready --json` → filter by skillset → claim

**Latency:** Equal to polling interval (15-60 min)  
**Cost:** One git pull + one bd query per cycle  
**Complexity:** Minimal—uses existing infrastructure

### Pub/Sub Addition (GitHub Webhooks → OpenClaw)

**Implementation:** GitHub webhook on beads-hub push → OpenClaw receives event → notifies relevant agent

**Latency:** Near-instant  
**Cost:** Webhook infrastructure; agent must be listening  
**Complexity:** Moderate—requires webhook endpoint and routing logic

### Recommendation: Start with Polling, Add Pub/Sub Later

For a fleet of 3-5 agents, polling every 15-60 minutes is entirely adequate. The latency is acceptable because:
- Most beads are created by Brenner during interactive sessions (sub-second latency not needed)
- Research and infrastructure tasks are inherently slow
- The cost of pub/sub infrastructure outweighs the latency benefit at this scale

**When to add pub/sub:** When fleet grows to >10 agents, or when real-time task markets (see §8) require instant dispatch.

## 8. Relation to On-Chain Agent Identity and Task Markets

### EIP-8004 and Agent Identity

While EIP-8004 (or similar proposals for native agent transactions on Ethereum) was not findable as a finalized standard, the concept is relevant: agents with on-chain identities could participate in decentralized task markets.

**How this connects to #B4mad:**

1. **Agent Identity:** Each agent (PltOps, CodeMonkey, Romanov) could have an on-chain identity (ENS name, smart account) that proves its capabilities and track record.

2. **On-Chain Task Markets:** Beads could be posted as on-chain bounties. External agents (not just #B4mad fleet) could bid on tasks. Smart contracts handle escrow and payment.

3. **Reputation:** Completed beads build an on-chain reputation score. Higher reputation → priority access to high-value tasks.

### Practical Assessment

This is aspirational for #B4mad's current stage. The pragmatic path:

1. **Phase 1 (Now):** Git-based pull scheduling with optimistic locking
2. **Phase 2 (6 months):** Add agent identity metadata to bead claims (preparing for portability)
3. **Phase 3 (12+ months):** Explore on-chain task posting for cross-organization agent collaboration

On-chain task markets make sense when there's a real multi-party ecosystem. For an internal fleet, git is the right coordination layer.

## 9. Proposed Architecture

```
┌─────────────────────────────────────────────┐
│              beads-hub (git)                 │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐       │
│  │bead1│  │bead2│  │bead3│  │bead4│  ...   │
│  │ready│  │ready│  │claim│  │done │        │
│  └─────┘  └─────┘  └─────┘  └─────┘       │
└──────┬──────────┬──────────┬────────────────┘
       │ git pull │ git pull │ git pull
       ▼          ▼          ▼
  ┌─────────┐ ┌──────────┐ ┌──────────┐
  │ PltOps  │ │CodeMonkey│ │ Romanov  │
  │ cron 15m│ │ cron 30m │ │ cron 60m │
  │         │ │          │ │          │
  │ filter: │ │ filter:  │ │ filter:  │
  │ infra/* │ │ code/*   │ │Research:*│
  └─────────┘ └──────────┘ └──────────┘
       │              │            │
       └──────────────┼────────────┘
                      ▼
              ┌──────────────┐
              │Brenner Axiom │
              │  (overseer)  │
              │ - escalations│
              │ - stall detect│
              │ - user comms │
              └──────────────┘
```

### Agent Heartbeat Loop (Pseudocode)

```python
def agent_heartbeat(agent_name, skillset_filter, interval):
    if check_capacity() == "busy":
        report_heartbeat(status="busy")
        return

    git_pull("beads-hub")
    beads = bd_ready(filter=skillset_filter)

    for bead in beads:
        if try_claim(bead, agent_name):
            execute_task(bead)
            bd_close(bead, reason="completed")
            git_push()
            break  # one task per cycle (or configurable)

    report_heartbeat(status="available")
```

### Skillset Filters

| Agent | Filter Pattern | Examples |
|-------|---------------|----------|
| PltOps | Title contains: `infra`, `cluster`, `CI/CD`, `deploy`, `monitor` | "Deploy new monitoring stack" |
| CodeMonkey | Title contains: `code`, `fix`, `refactor`, `implement`, `PR` | "Implement webhook handler" |
| Romanov | Title prefix: `Research:` | "Research: Pull-based scheduling" |
| Brenner | Everything not claimed after 2 cycles (fallback) | Uncategorized tasks |

## 10. Recommendations

### Immediate Actions (This Sprint)

1. **Add `bd claim` command** to beads CLI with optimistic git locking
2. **Add agent-status directory** to beads-hub for capacity reporting
3. **Create cron jobs** for each specialist agent with appropriate intervals
4. **Define skillset filters** in agent configuration (AGENTS.md or per-agent config)

### Short-Term (Next Month)

5. **Implement adaptive polling** (backoff when queue empty, speed up when busy)
6. **Add stale-task detection** in Brenner's heartbeat (flag beads in_progress >2× expected duration)
7. **Dashboard** showing agent status and bead flow (simple markdown table auto-generated)

### Medium-Term (3-6 Months)

8. **GitHub webhook notification** to reduce polling latency when needed
9. **Agent identity metadata** in bead claims (preparing for cross-org portability)
10. **Metrics collection** on task throughput, claim-to-completion time, conflict rate

### Not Recommended (Yet)

- Full pub/sub infrastructure (NATS, Kafka) — overkill for <10 agents
- On-chain task markets — no multi-party ecosystem to justify gas costs
- Actor model runtime — adds complexity without proportional benefit at our scale

## 11. Conclusion

The transition from push to pull scheduling for #B4mad's agent fleet is both natural and low-risk. The beads-hub git repository already provides the shared work queue; adding a claim protocol with optimistic locking via git push/pull is the minimal viable change. Each specialist agent gains autonomy through cron-based polling with skillset filters, while Brenner Axiom shifts from dispatcher to overseer—handling escalations, stale tasks, and user communication.

The architecture is deliberately simple. Git is the coordination layer. Polling intervals are generous. Conflict resolution uses git's built-in mechanisms. This simplicity is a feature: it matches the fleet's current scale (3-5 agents) and avoids premature infrastructure investment. Pub/sub and on-chain markets remain viable future extensions when scale demands them.

**The right architecture for #B4mad today is: pull-based polling over git, with optimistic locking, adaptive intervals, and Brenner as fallback overseer.**

## References

1. Burns, B., Grant, B., Oppenheimer, D., Brewer, E., & Wilkes, J. (2016). "Borg, Omega, and Kubernetes." ACM Queue, 14(1).
2. Limón, X. (2023). "GitOps: The Path to a Fully Automated CI/CD Pipeline." ArgoCD Documentation.
3. Armstrong, J. (2003). "Making Reliable Distributed Systems in the Presence of Software Errors." PhD Thesis, Royal Institute of Technology, Stockholm.
4. Agha, G. (1986). "Actors: A Model of Concurrent Computation in Distributed Systems." MIT Press.
5. CrewAI Documentation (2025). "Tasks and Process Orchestration." https://docs.crewai.com/concepts/tasks
6. Wu, Q., et al. (2023). "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation." Microsoft Research.
7. Kubernetes Documentation (2025). "Scheduling, Preemption and Eviction." https://kubernetes.io/docs/concepts/scheduling-eviction/
8. Weaveworks (2024). "GitOps: What You Need to Know." https://www.weave.works/technologies/gitops/
