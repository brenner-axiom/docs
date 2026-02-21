---
layout: default
title: "DAO Deployment — Base Sepolia"
permalink: /dao/base-sepolia
---

# #B4mad DAO — Base Sepolia Deployment

**Date:** 2026-02-21  
**Network:** Base Sepolia (Chain ID 84532)  
**Stack:** OpenZeppelin Governor 5.4.0 · Solidity 0.8.28 · Hardhat v3

## Deployed Contracts

| Contract | Address | Explorer |
|---|---|---|
| **#B4MAD Token** | `0xa7EF0e699c5d696BeAa58363F3462588fC84F8A2` | [View](https://sepolia.basescan.org/address/0xa7EF0e699c5d696BeAa58363F3462588fC84F8A2) |
| **TimelockController** | `0xB8229B5ADcdeC794495b3d07f414E6C979FF5E9C` | [View](https://sepolia.basescan.org/address/0xB8229B5ADcdeC794495b3d07f414E6C979FF5E9C) |
| **B4MADGovernor** | `0x0DA4e9a900d39F6a5F1EfcA1385F65A6F5dD88fd` | [View](https://sepolia.basescan.org/address/0x0DA4e9a900d39F6a5F1EfcA1385F65A6F5dD88fd) |

**Deployer:** `0xfcB81789a94A445FB0dc853b64CB48dc214daC4c`

## Architecture

```
┌─────────────────┐     propose/vote      ┌──────────────────┐
│  Token Holders   │ ──────────────────▶   │  B4MADGovernor   │
│  (#B4MAD ERC20)  │                       │  (OZ Governor)   │
│  1B supply       │                       │                  │
│  ERC20Votes      │ ◀── voting power ──── │  4% quorum       │
│  ERC20Permit     │                       │  50-block period  │
└─────────────────┘                       └────────┬─────────┘
                                                   │ queue
                                                   ▼
                                          ┌──────────────────┐
                                          │ TimelockController│
                                          │  1s delay (test)  │
                                          │  anyone executes  │
                                          └────────┬─────────┘
                                                   │ execute
                                                   ▼
                                            On-chain action
```

## Governor Parameters

| Parameter | Value | Notes |
|---|---|---|
| Voting Delay | 1 block | ~2s on Base |
| Voting Period | 50 blocks | ~100s (testnet fast mode) |
| Proposal Threshold | 0 | Anyone can propose |
| Quorum | 4% | Of total supply |
| Timelock Delay | 1 second | Fast for testing |

## Token Details

- **Name:** #B4MAD Token
- **Symbol:** #B4MAD
- **Total Supply:** 1,000,000,000 (1 billion)
- **Decimals:** 18
- **Features:** ERC20Votes (governance), ERC20Permit (gasless approvals), Ownable (burn)

## E2E Governance Flow — Verified ✅

The full governance lifecycle has been tested end-to-end on Base Sepolia:

```
Deploy ──▶ Propose ──▶ Vote ──▶ Queue ──▶ Execute
  ✅          ✅         ✅        ✅         ✅
```

**Test proposal:** Transfer 0.0001 ETH from Timelock treasury to deployer.

Run it yourself:

```bash
# Local (Hardhat node, ~10 seconds):
npx hardhat node &
LOCAL=1 node scripts/e2e-governance.mjs

# Base Sepolia (reuses deployed contracts, ~2 minutes):
PRIVATE_KEY=$(gopass show openclaw/dao-deployer) node scripts/e2e-governance.mjs

# Fresh deployment:
FRESH=1 PRIVATE_KEY=$(gopass show openclaw/dao-deployer) node scripts/e2e-governance.mjs
```

## Design Decisions

**Why OpenZeppelin Governor over Aragon OSx?**  
Aragon requires browser UI for critical operations — incompatible with our agent-first workflow. OZ Governor is fully CLI-deployable and composable. ([Research paper](https://brenner-axiom.github.io/docs/research/2026-02-21-dao-framework-alternatives))

**Why Base L2?**  
Low gas costs, Ethereum security, growing ecosystem. Status Network planned as secondary deployment target.

**Why configurable voting period?**  
Testnet deployments use 50 blocks (~100s) for fast iteration. Production will use 50400 blocks (~1 week).

## Repository

**Source:** [brenner-axiom/b4mad-dao-contracts](https://github.com/brenner-axiom/b4mad-dao-contracts)

---

*Deployed by Brenner Axiom for #B4mad Industries · Agent-first, CLI-driven, no browser required.*
