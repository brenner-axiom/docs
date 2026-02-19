# Getting Started with the #B4mad DAO

> **Bead:** beads-hub-e3a — "DAO Phase 1.5: Tutorial for DAO interaction"

This tutorial walks you through interacting with the **#B4mad DAO** as a contributor — from understanding the governance token to voting on proposals and checking the treasury.

## Prerequisites

- **Docker** (for the containerized dev environment)
- **Node.js ≥ 18** (for ethers.js examples)
- **Foundry** (`cast` CLI) — [install guide](https://book.getfoundry.sh/getting-started/installation)

### Dev Environment

All contract ABIs and deployment artifacts are available in our container image:

```bash
docker pull ghcr.io/brenner-axiom/b4mad-dao-contracts:latest

# Run an interactive shell with all tools pre-installed
docker run -it --rm ghcr.io/brenner-axiom/b4mad-dao-contracts:latest bash
```

Inside the container you'll find:
- Compiled contract ABIs in `/app/artifacts/`
- Deployment addresses in `/app/deployments/`
- Pre-configured `foundry.toml` and helper scripts

### Environment Variables

Set these before running the examples below:

```bash
# RPC endpoint (use the network where the DAO is deployed)
export RPC_URL="https://rpc.gnosis.gateway.fm"

# Contract addresses (check /app/deployments/ in the container for current values)
export TOKEN_ADDRESS="0x..."        # $B4MAD ERC-20 governance token
export GOVERNOR_ADDRESS="0x..."     # Governor contract (OpenZeppelin Governor)
export TIMELOCK_ADDRESS="0x..."     # TimelockController (treasury)
export YOUR_ADDRESS="0x..."         # Your wallet address
export PRIVATE_KEY="0x..."          # Your private key (NEVER commit this)
```

---

## 1. What Is the $B4MAD Governance Token?

The **$B4MAD** token is an [ERC-20](https://eips.ethereum.org/EIPS/eip-20) governance token with [ERC20Votes](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Votes) extensions. It powers the #B4mad DAO:

| Property | Details |
|---|---|
| **Standard** | ERC-20 + ERC20Votes (OpenZeppelin) |
| **Voting weight** | 1 token = 1 vote (delegated) |
| **Delegation** | You **must delegate** before your tokens count as voting power — even to yourself |
| **Transferable** | Yes, but governance weight follows delegation |

### Key Concept: Delegation

Holding tokens alone does **not** give you voting power. You must delegate your votes — either to yourself or to another address you trust.

#### ethers.js — Delegate to Yourself

```js
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const tokenAbi = [
  "function delegate(address delegatee) external",
  "function delegates(address account) external view returns (address)",
  "function getVotes(address account) external view returns (uint256)",
];
const token = new ethers.Contract(process.env.TOKEN_ADDRESS, tokenAbi, signer);

// Delegate votes to yourself
const tx = await token.delegate(signer.address);
await tx.wait();
console.log("Delegated to:", await token.delegates(signer.address));
console.log("Voting power:", ethers.formatEther(await token.getVotes(signer.address)));
```

#### cast — Delegate to Yourself

```bash
cast send $TOKEN_ADDRESS "delegate(address)" $YOUR_ADDRESS \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

---

## 2. How to Receive Tokens (Contributor Allocation)

$B4MAD tokens are allocated to contributors by the DAO through governance proposals. The typical flow:

1. **A proposal is created** to mint/transfer tokens to a contributor's address
2. **Token holders vote** on the proposal
3. **After the voting period**, if quorum is met and the vote passes, the proposal is queued
4. **After the timelock delay**, anyone can execute the proposal, and tokens are transferred

### Check Your Token Balance

#### ethers.js

```js
const balanceAbi = ["function balanceOf(address) view returns (uint256)"];
const token = new ethers.Contract(process.env.TOKEN_ADDRESS, balanceAbi, provider);

const balance = await token.balanceOf(process.env.YOUR_ADDRESS);
console.log("Balance:", ethers.formatEther(balance), "$B4MAD");
```

#### cast

```bash
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $YOUR_ADDRESS \
  --rpc-url $RPC_URL | cast from-wei
```

---

## 3. How to View Proposals

The DAO uses an [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/4.x/governance) contract. Each proposal has a unique `proposalId` (a uint256 hash).

### Proposal States

| State | Meaning |
|---|---|
| 0 — Pending | Voting hasn't started yet |
| 1 — Active | Voting is open |
| 2 — Canceled | Proposal was canceled |
| 3 — Defeated | Vote failed (quorum not met or more against) |
| 4 — Succeeded | Vote passed, awaiting queue |
| 5 — Queued | In timelock, awaiting execution |
| 6 — Expired | Timelock expired without execution |
| 7 — Executed | Proposal was executed |

#### ethers.js — Check Proposal State

```js
const governorAbi = [
  "function state(uint256 proposalId) view returns (uint8)",
  "function proposalVotes(uint256 proposalId) view returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)",
  "function proposalDeadline(uint256 proposalId) view returns (uint256)",
  "function proposalSnapshot(uint256 proposalId) view returns (uint256)",
];
const governor = new ethers.Contract(process.env.GOVERNOR_ADDRESS, governorAbi, provider);

const proposalId = "123..."; // The proposal ID you want to check

const state = await governor.state(proposalId);
const stateNames = ["Pending", "Active", "Canceled", "Defeated", "Succeeded", "Queued", "Expired", "Executed"];
console.log("State:", stateNames[state]);

const [against, forVotes, abstain] = await governor.proposalVotes(proposalId);
console.log(`Votes — For: ${ethers.formatEther(forVotes)}, Against: ${ethers.formatEther(against)}, Abstain: ${ethers.formatEther(abstain)}`);
```

#### cast — Check Proposal State

```bash
# Get proposal state (returns a number 0-7)
cast call $GOVERNOR_ADDRESS "state(uint256)(uint8)" $PROPOSAL_ID \
  --rpc-url $RPC_URL

# Get vote tallies
cast call $GOVERNOR_ADDRESS \
  "proposalVotes(uint256)(uint256,uint256,uint256)" $PROPOSAL_ID \
  --rpc-url $RPC_URL
```

---

## 4. How to Vote on Proposals

You can vote **For** (1), **Against** (0), or **Abstain** (2) on any active proposal where you had delegated voting power at the proposal's snapshot block.

#### ethers.js — Cast a Vote

```js
const governorAbi = [
  "function castVote(uint256 proposalId, uint8 support) external returns (uint256)",
  "function castVoteWithReason(uint256 proposalId, uint8 support, string reason) external returns (uint256)",
  "function hasVoted(uint256 proposalId, address account) view returns (bool)",
];
const governor = new ethers.Contract(process.env.GOVERNOR_ADDRESS, governorAbi, signer);

const proposalId = "123...";

// Vote FOR (1) with a reason
const tx = await governor.castVoteWithReason(proposalId, 1, "Strong proposal, aligns with roadmap");
const receipt = await tx.wait();
console.log("Vote cast! Tx:", receipt.hash);

// Check if you've voted
const voted = await governor.hasVoted(proposalId, signer.address);
console.log("Has voted:", voted);
```

#### cast — Cast a Vote

```bash
# Vote FOR (support=1)
cast send $GOVERNOR_ADDRESS \
  "castVoteWithReason(uint256,uint8,string)" \
  $PROPOSAL_ID 1 "Looks good to me" \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check if you already voted
cast call $GOVERNOR_ADDRESS \
  "hasVoted(uint256,address)(bool)" \
  $PROPOSAL_ID $YOUR_ADDRESS \
  --rpc-url $RPC_URL
```

---

## 5. How to Check Treasury Status

The DAO treasury is managed by the **TimelockController** contract. Any ETH or ERC-20 tokens held by the timelock address are DAO funds.

#### ethers.js — Check Treasury

```js
// Check native token (ETH/xDAI) balance
const treasuryBalance = await provider.getBalance(process.env.TIMELOCK_ADDRESS);
console.log("Treasury native balance:", ethers.formatEther(treasuryBalance));

// Check $B4MAD tokens held by treasury
const tokenAbi = ["function balanceOf(address) view returns (uint256)"];
const token = new ethers.Contract(process.env.TOKEN_ADDRESS, tokenAbi, provider);

const tokenBalance = await token.balanceOf(process.env.TIMELOCK_ADDRESS);
console.log("Treasury $B4MAD balance:", ethers.formatEther(tokenBalance));
```

#### cast — Check Treasury

```bash
# Native balance (ETH/xDAI)
cast balance $TIMELOCK_ADDRESS --rpc-url $RPC_URL | cast from-wei

# $B4MAD token balance in treasury
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $TIMELOCK_ADDRESS \
  --rpc-url $RPC_URL | cast from-wei
```

---

## Quick Reference

| Action | cast one-liner |
|---|---|
| Check balance | `cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $YOUR_ADDRESS --rpc-url $RPC_URL` |
| Delegate votes | `cast send $TOKEN_ADDRESS "delegate(address)" $YOUR_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY` |
| Check voting power | `cast call $TOKEN_ADDRESS "getVotes(address)(uint256)" $YOUR_ADDRESS --rpc-url $RPC_URL` |
| Proposal state | `cast call $GOVERNOR_ADDRESS "state(uint256)(uint8)" $PROPOSAL_ID --rpc-url $RPC_URL` |
| Vote FOR | `cast send $GOVERNOR_ADDRESS "castVote(uint256,uint8)" $PROPOSAL_ID 1 --rpc-url $RPC_URL --private-key $PRIVATE_KEY` |
| Treasury balance | `cast balance $TIMELOCK_ADDRESS --rpc-url $RPC_URL` |

---

## Next Steps

- **Explore the contracts** inside the dev container: `docker run -it ghcr.io/brenner-axiom/b4mad-dao-contracts:latest bash`
- **Read the OpenZeppelin Governor docs**: [docs.openzeppelin.com/contracts/4.x/governance](https://docs.openzeppelin.com/contracts/4.x/governance)
- **Join the #B4mad community** to discuss proposals before they go on-chain

---

*Last updated: 2026-02-19 · Bead: beads-hub-e3a*
