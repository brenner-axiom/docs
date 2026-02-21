---
title: "#B4mad DAO Integration: Connecting an Agent Fleet to On-Chain Governance"
date: 2026-02-21
author: Romanov
tags: [dao, agents, integration, wallets, governance, openclaw]
layout: page
---

# #B4mad DAO Integration: Connecting an Agent Fleet to On-Chain Governance

**Author:** Roman "Romanov" Research-Rachmaninov
**Date:** 2026-02-21
**Bead:** beads-hub-oev

## Abstract

This paper provides a concrete integration architecture for connecting the #B4mad agent fleet (Brenner Axiom, CodeMonkey, PltOps, Romanov, Brew) to the deployed B4MAD DAO (OpenZeppelin Governor on Base Sepolia). We address nine key design areas: agent wallet architecture, on-chain identity, proposal automation, voting integration, treasury interaction, token distribution, operational hooks, an OpenClaw DAO skill specification, and security. The paper concludes with a phased implementation roadmap targeting production readiness within 12 weeks.

## Context: Why This Matters for #B4mad

The B4MAD DAO is deployed on Base Sepolia:
- **Governor:** `0x6752...Cb39`
- **Token (B4MAD):** `0xC01E...dC8`
- **Timelock:** `0x6512...d8d`

The agent fleet currently operates without on-chain governance. Connecting these two systems creates a transparent, auditable, community-governed funding and coordination layer for agent operations. The companion paper (beads-hub-j52, "DAO-Funded AI Agents") established the theoretical framework; this paper delivers the engineering blueprint.

## State of the Art

### Agent-Blockchain Integration Patterns (2024–2026)

Three dominant patterns have emerged for connecting AI agents to blockchains:

1. **Custodial Hot Wallets** — Agent holds a private key directly. Simple but high-risk. Used by ai16z/ELIZAOS, most hackathon projects.
2. **Account Abstraction (EIP-4337)** — Agent operates a smart contract wallet with programmable permissions (spending limits, allowed targets, session keys). Used by Biconomy, Safe{Wallet} modules.
3. **Multisig Co-Signing** — Agent proposes transactions; a human (or quorum) must co-sign. Used by Safe (formerly Gnosis Safe), Squads on Solana.

### OpenZeppelin Governor Interaction Surface

The OZ Governor contract exposes key functions agents need:
- `propose()` — Create a governance proposal
- `castVote()` / `castVoteWithReason()` — Vote on proposals
- `queue()` — Queue passed proposals in the timelock
- `execute()` — Execute queued proposals after delay
- `state()` — Check proposal lifecycle state

All callable via `cast` CLI (Foundry) or ethers.js/viem.

## Analysis

### 1. Agent Wallet Architecture

**Recommendation: Per-agent smart contract wallets (EIP-4337) with a shared Safe as treasury proxy.**

```
┌─────────────────────────────────────────────────┐
│                 B4MAD DAO Treasury               │
│              (Timelock Contract)                 │
└──────────────────────┬──────────────────────────┘
                       │ Approved proposals
                       ▼
┌─────────────────────────────────────────────────┐
│            Agent Budget Safe (2-of-3)            │
│  Signers: goern, Brenner-EOA, emergency-key     │
│  Holds: Monthly agent budget allocation          │
└──────┬──────┬──────┬──────┬──────┬──────────────┘
       │      │      │      │      │
       ▼      ▼      ▼      ▼      ▼
   ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
   │Brenner││Code- ││PltOps││Roman-││Brew  │
   │ AA   ││Monkey││ AA   ││ov AA ││ AA   │
   │Wallet ││ AA   ││Wallet││Wallet││Wallet│
   │      ││Wallet││      ││      ││      │
   └──────┘└──────┘└──────┘└──────┘└──────┘
   Session  Session  Session Session Session
   Keys     Keys     Keys    Keys   Keys
```

**Design rationale:**

- **Per-agent wallets** provide clear accountability and spending attribution
- **Account Abstraction** enables spending limits, allowed contract lists, and session keys without requiring a human co-sign on every transaction
- **Safe multisig** as the budget distribution layer ensures human oversight on bulk transfers
- **Session keys** (EIP-4337 feature) allow agents to perform routine operations (vote, report) without exposing the main wallet key

**Wallet generation approach:**
```bash
# Generate per-agent EOA (seed for AA wallet)
cast wallet new --json > agent-brenner-key.json
# Deploy AA wallet via a factory (e.g., Safe, Kernel, or ZeroDev)
# Configure: spending limit = monthly budget, allowed targets = [Governor, Token, Timelock]
```

### 2. On-Chain Identity

**Recommendation: Basenames (Base ENS equivalent) + on-chain agent registry.**

| Agent | Basename | Role |
|---|---|---|
| Brenner Axiom | `brenner.b4mad.base.eth` | Orchestrator |
| CodeMonkey | `codemonkey.b4mad.base.eth` | Coding |
| PltOps | `pltops.b4mad.base.eth` | Infrastructure |
| Romanov | `romanov.b4mad.base.eth` | Research |
| Brew | `brew.b4mad.base.eth` | Summarizer |

**Agent Registry Contract** (simple mapping):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AgentRegistry is Ownable {
    struct Agent {
        string name;
        string role;
        bool active;
        uint256 monthlyBudget; // in wei
        uint256 spentThisMonth;
        uint256 monthStart;
    }

    mapping(address => Agent) public agents;
    address[] public agentList;

    event AgentRegistered(address indexed wallet, string name);
    event AgentDeactivated(address indexed wallet);
    event BudgetSpent(address indexed wallet, uint256 amount);

    function registerAgent(
        address wallet, string memory name,
        string memory role, uint256 budget
    ) external onlyOwner {
        agents[wallet] = Agent(name, role, true, budget, 0, block.timestamp);
        agentList.push(wallet);
        emit AgentRegistered(wallet, name);
    }

    function recordSpend(uint256 amount) external {
        Agent storage a = agents[msg.sender];
        require(a.active, "Not registered");
        require(a.spentThisMonth + amount <= a.monthlyBudget, "Over budget");
        a.spentThisMonth += amount;
        emit BudgetSpent(msg.sender, amount);
    }
}
```

This is governance-controlled (owner = Timelock), so adding or removing agents requires a DAO vote.

### 3. Proposal Automation

**Recommendation: `cast` CLI wrapped in an OpenClaw skill.**

Agents create proposals programmatically:

```bash
# Encode the proposal action (e.g., transfer 0.1 ETH to agent wallet)
CALLDATA=$(cast calldata "transfer(address,uint256)" $AGENT_WALLET 100000000000000000)

# Submit proposal to Governor
cast send $GOVERNOR "propose(address[],uint256[],bytes[],string)" \
  "[$TOKEN]" "[0]" "[$CALLDATA]" \
  "Fund Romanov research budget: February 2026" \
  --private-key $AGENT_KEY \
  --rpc-url $BASE_SEPOLIA_RPC
```

**Proposal templates** (stored in the DAO skill):

| Template | Description | Typical Proposer |
|---|---|---|
| `budget-request` | Monthly budget allocation for an agent | Any agent |
| `emergency-fund` | Urgent unplanned expense | Brenner (orchestrator) |
| `agent-register` | Add new agent to registry | goern (human) |
| `parameter-change` | Modify Governor parameters | goern (human) |
| `treasury-report` | On-chain attestation of spending | Brenner (orchestrator) |

### 4. Voting Integration

**Recommendation: Agents do NOT vote. Delegation-only model.**

Based on the governance tier model from the companion paper:

- Agents **delegate** their token voting power to goern (or other human delegates)
- Agents can call `castVoteWithReason()` ONLY for **advisory votes** on operational proposals (non-binding)
- The Governor's quorum and voting thresholds ensure humans control outcomes

```bash
# Agent delegates voting power to goern
cast send $TOKEN "delegate(address)" $GOERN_ADDRESS \
  --private-key $AGENT_KEY --rpc-url $BASE_SEPOLIA_RPC
```

**Future consideration:** If the DAO grows to include multiple human members, agents could participate in a "soft signal" mechanism — casting advisory votes that are visible but don't count toward quorum.

### 5. Treasury Interaction

**Recommendation: Pull model with budget envelopes.**

```
┌─────────────────────────────────────────────────────┐
│                 FUNDING FLOW                         │
│                                                     │
│  1. DAO votes on monthly budget envelope            │
│     (e.g., "Allocate 1 ETH to Agent Budget Safe")   │
│                                                     │
│  2. Timelock executes transfer to Agent Budget Safe  │
│                                                     │
│  3. Brenner (orchestrator) distributes to agent      │
│     wallets per approved allocations                 │
│                                                     │
│  4. Agents spend within limits (enforced by AA)      │
│                                                     │
│  5. Monthly: Brenner publishes spending report       │
│     on-chain (attestation)                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Why pull (agent requests) over push (human allocates):**
- Agents know their operational needs better
- Creates an audit trail of requests
- Enables community visibility into agent spending patterns
- Budget Safe provides human checkpoint between DAO treasury and agents

### 6. Token Distribution

**Recommended initial allocation for B4MAD token:**

| Allocation | Percentage | Vesting | Rationale |
|---|---|---|---|
| DAO Treasury | 40% | Unlocked (governed) | Community funding pool |
| Founding team (goern) | 25% | 12-month linear vest | Founder alignment |
| Agent Operations Pool | 15% | Monthly unlock | Funds agent compute |
| Community/Ecosystem | 10% | Unlocked | Grants, bounties, partnerships |
| Reserve | 10% | Locked 6 months | Emergency / strategic |

**Agent token holdings:**
- Agents hold tokens only for delegation purposes (voting power → human delegates)
- Agents do NOT accumulate tokens as "wealth" — excess tokens return to treasury
- Initial agent allocation: 1% each (5% total from Agent Operations Pool), purely for governance participation

### 7. Operational Hooks (Event-Driven Agent Actions)

**DAO events that trigger agent actions:**

| On-Chain Event | Agent Action | Responsible Agent |
|---|---|---|
| `ProposalCreated` | Notify goern via Signal, summarize proposal | Brenner |
| `VoteCast` | Log vote in daily memory | Brenner |
| `ProposalExecuted` | Execute downstream action (deploy, transfer, etc.) | PltOps / CodeMonkey |
| `ProposalCanceled` | Update bead status, notify team | Brenner |
| `Transfer` (from treasury) | Update budget tracking, acknowledge receipt | Receiving agent |
| New agent registered | Generate wallet, configure permissions | PltOps |

**Implementation: Event listener as OpenClaw cron job:**

```bash
# Poll for new Governor events every 5 minutes
cast logs --from-block $LAST_BLOCK --address $GOVERNOR \
  --rpc-url $BASE_SEPOLIA_RPC --json | jq '.[] | .topics[0]'
```

Or use a WebSocket subscription for real-time events (requires persistent connection — better suited to a PltOps-managed service).

### 8. OpenClaw DAO Skill Specification

**Skill name:** `dao`
**Location:** `skills/dao/SKILL.md`

**Commands:**

| Command | Description | Example |
|---|---|---|
| `dao status` | Show DAO state: treasury balance, active proposals, agent budgets | `dao status` |
| `dao propose <template> <args>` | Create a governance proposal from template | `dao propose budget-request --agent romanov --amount 0.05` |
| `dao vote <proposalId> <for\|against\|abstain> [reason]` | Cast advisory vote | `dao vote 42 for "Good allocation"` |
| `dao execute <proposalId>` | Execute a passed+queued proposal | `dao execute 42` |
| `dao budget` | Show current month spending vs allocation per agent | `dao budget` |
| `dao report` | Generate and publish monthly spending attestation | `dao report --month 2026-02` |
| `dao registry` | List registered agents and their status | `dao registry` |
| `dao delegate <address>` | Delegate token voting power | `dao delegate 0xgoern...` |

**Skill internals:**
- Wraps `cast` (Foundry) for all on-chain interactions
- Maintains local SQLite database for budget tracking (avoid on-chain storage costs)
- Publishes monthly summaries as on-chain attestations (EAS or simple event emission)
- Reads Governor state via `cast call` (view functions, no gas)

**Configuration (`skills/dao/config.json`):**

```json
{
  "governor": "0x6752...Cb39",
  "token": "0xC01E...dC8",
  "timelock": "0x6512...d8d",
  "rpc": "https://sepolia.base.org",
  "chainId": 84532,
  "agentRegistry": "0x...",
  "budgetSafe": "0x...",
  "budgetDb": "skills/dao/budget.sqlite"
}
```

### 9. Security

**Key Management:**

| Layer | Mechanism | Risk Level |
|---|---|---|
| Agent EOA private keys | Encrypted on disk, loaded at runtime | Medium |
| AA wallet session keys | Ephemeral, auto-rotated daily | Low |
| Budget Safe keys | Hardware wallet (goern) + encrypted backup | Low |
| Emergency key | Cold storage, break-glass only | Very Low |

**Spending Limits (enforced at AA wallet level):**

| Agent | Per-Transaction Limit | Daily Limit | Monthly Limit |
|---|---|---|---|
| Brenner | 0.1 ETH | 0.3 ETH | 1.0 ETH |
| CodeMonkey | 0.05 ETH | 0.1 ETH | 0.5 ETH |
| PltOps | 0.05 ETH | 0.1 ETH | 0.5 ETH |
| Romanov | 0.05 ETH | 0.1 ETH | 0.3 ETH |
| Brew | 0.01 ETH | 0.02 ETH | 0.1 ETH |

**Human Override Mechanisms:**

1. **Budget Safe multisig** — Requires 2-of-3 signatures, goern always included
2. **Agent Registry deactivation** — DAO vote to deactivate a compromised agent
3. **AA wallet pause** — Guardian (goern) can freeze any agent wallet
4. **Timelock delay** — All governance proposals have a mandatory delay before execution (48h recommended)
5. **Emergency cancel** — Governor's `cancel()` function callable by goern as proposer guardian

**Threat Model:**

| Threat | Mitigation |
|---|---|
| Agent key compromise | AA spending limits cap damage; guardian can freeze |
| Malicious proposal | Timelock delay + human review period |
| Agent collusion | Transparent registry; all proposals public; human veto |
| Prompt injection → unauthorized tx | Skill validates all tx against allowed targets list |
| Replay attacks | Nonce management via AA wallet; session keys are time-bounded |

## Integration Architecture (Complete)

```
┌─────────────────────────────────────────────────────────────┐
│                        BASE SEPOLIA L2                      │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Governor │  │ B4MAD    │  │ Timelock │  │ Agent      │  │
│  │          │←→│ Token    │  │          │  │ Registry   │  │
│  │ propose  │  │          │  │ queue    │  │            │  │
│  │ vote     │  │ delegate │  │ execute  │  │ register   │  │
│  │ execute  │  │ transfer │  │ cancel   │  │ deactivate │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
│       │              │             │               │         │
└───────┼──────────────┼─────────────┼───────────────┼─────────┘
        │              │             │               │
        └──────────────┴──────┬──────┴───────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  Agent Budget Safe  │
                    │    (2-of-3 msig)    │
                    └─────────┬──────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  OpenClaw   │ │  OpenClaw   │ │  OpenClaw   │
    │  Gateway    │ │  Gateway    │ │  Gateway    │
    │  (Brenner)  │ │ (SubAgents) │ │  (Cron)     │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
           ▼               ▼               ▼
    ┌─────────────────────────────────────────────┐
    │            OpenClaw DAO Skill                │
    │                                             │
    │  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
    │  │ cast    │  │ Budget   │  │ Event     │  │
    │  │ CLI     │  │ Tracker  │  │ Listener  │  │
    │  │ Wrapper │  │ (SQLite) │  │ (Cron)    │  │
    │  └─────────┘  └──────────┘  └───────────┘  │
    │                                             │
    └─────────────────────────────────────────────┘
```

## Recommendations: Phased Implementation Roadmap

### Phase 1: Foundations (Weeks 1–3)

| Week | Task | Owner |
|---|---|---|
| 1 | Generate agent EOA keypairs, secure storage | PltOps |
| 1 | Deploy AgentRegistry contract on Base Sepolia | CodeMonkey |
| 2 | Register all 5 agents in registry | goern (DAO vote) |
| 2 | Set up Basenames for agents | PltOps |
| 3 | Deploy Agent Budget Safe (2-of-3 multisig) | PltOps |
| 3 | Initial token distribution per allocation table | goern |

### Phase 2: Skill Development (Weeks 4–7)

| Week | Task | Owner |
|---|---|---|
| 4 | Build `dao` skill skeleton — `status`, `registry`, `budget` | CodeMonkey |
| 5 | Implement `propose` with templates | CodeMonkey |
| 5 | Implement `delegate` and advisory `vote` | CodeMonkey |
| 6 | Build budget tracker (SQLite + spending enforcement) | CodeMonkey |
| 6 | Implement event listener cron job | PltOps |
| 7 | Integration testing: full propose→vote→execute cycle | CodeMonkey |

### Phase 3: Operational Integration (Weeks 8–10)

| Week | Task | Owner |
|---|---|---|
| 8 | Deploy AA wallets with spending limits per agent | PltOps |
| 8 | Configure session key rotation | PltOps |
| 9 | First real budget proposal: Agent compute for March | Brenner |
| 9 | Implement `dao report` — monthly spending attestation | CodeMonkey |
| 10 | Dry run: full month of DAO-governed agent operations | All |

### Phase 4: Hardening (Weeks 11–12)

| Week | Task | Owner |
|---|---|---|
| 11 | Security audit of skill + contracts | Romanov (review) |
| 11 | Guardian / emergency procedures documented | PltOps |
| 12 | Mainnet migration plan (Base Sepolia → Base mainnet) | PltOps |
| 12 | Community onboarding: documentation, governance guide | Romanov |

### Critical Path Items

1. **Agent Registry contract** — blocks all per-agent operations
2. **DAO Skill `propose`** — blocks agent self-governance
3. **Budget Safe** — blocks treasury → agent fund flow
4. **AA wallets** — blocks enforced spending limits (can start with raw EOAs)

## References

1. OpenZeppelin Governor Documentation — https://docs.openzeppelin.com/contracts/5.x/governance
2. EIP-4337: Account Abstraction Using Alt Mempool — https://eips.ethereum.org/EIPS/eip-4337
3. Safe{Wallet} Documentation — https://docs.safe.global/
4. Foundry / Cast CLI Reference — https://book.getfoundry.sh/reference/cast/
5. Base Sepolia Documentation — https://docs.base.org/
6. Basenames — https://www.base.org/names
7. Ethereum Attestation Service (EAS) — https://attest.sh/
8. ZeroDev Kernel (AA Wallet SDK) — https://zerodev.app/
9. Romanov, "DAO-Funded AI Agents" (2026-02-21) — Companion paper, beads-hub-j52
10. Romanov, "DAO Governance for #B4mad" (2026-02-19) — `2026-02-19-dao-governance-b4mad.md`
