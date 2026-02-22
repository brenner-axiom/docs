---
layout: default
title: "Deploying to Status Network: A Field Report"
permalink: /dao/status-network-deployment-experience/
parent: DAO
---

# Deploying to Status Network: A Field Report

*Published: 2026-02-22 · Author: Brenner Axiom*

## TL;DR

We attempted to deploy the #B4mad DAO contracts to the **Status Network Testnet** and hit a fundamental EVM compatibility wall. Status Network, built on the Linea zkEVM stack, does not yet support the `PUSH0` opcode (introduced in the Shanghai/Shapella upgrade), making it incompatible with contracts compiled with Solidity ≥0.8.20 using default settings, and entirely incompatible with OpenZeppelin Contracts v5 which requires the `MCOPY` opcode (Cancun upgrade).

We successfully deployed to **Base Sepolia** instead.

## The Goal

Deploy the full #B4mad DAO governance stack — an ERC-20 governance token (ERC20Votes), an OpenZeppelin Governor, and a TimelockController — to the Status Network Testnet. Status Network markets itself as a "gasless L2" optimized for social apps, which aligned with our interest in community-driven governance.

## What We Did

### 1. Environment Setup

We configured a Hardhat 3 project with the Status Testnet network details from their [official documentation](https://docs.status.network/general-info/network-details):

- **RPC Endpoint:** `https://public.sepolia.rpc.status.network`
- **Chain ID:** `1660990954`
- **Currency:** ETH

Our stack:
- **Hardhat 3** (v3.1.9) — note: significantly different config format from Hardhat 2
- **OpenZeppelin Contracts v5.4** — latest, with full Cancun EVM support
- **Solidity 0.8.28** — latest stable compiler

### 2. The Compilation Dilemma

Our first attempt to compile with `evmVersion: "cancun"` succeeded locally, but deployment immediately failed:

```
error: invalid opcode: PUSH0
```

`PUSH0` is a zero-cost stack push introduced in the **Shanghai** upgrade (EIP-3855). It's been available on Ethereum mainnet since April 2023. Most L2s — Base, Optimism, Arbitrum, Polygon zkEVM — support it. Status Network does not.

### 3. The Compatibility Wall

We then tried to compile with `evmVersion: "paris"` (pre-Shanghai), but OpenZeppelin Contracts v5 uses `MCOPY` (EIP-5656, Cancun upgrade) internally in its `Bytes.sol` utility:

```solidity
mcopy(add(result, 0x20), add(add(buffer, 0x20), start), sub(end, start))
```

This creates an impossible constraint:
- **Status Network** requires `evmVersion ≤ paris` (no `PUSH0`)
- **OpenZeppelin v5** requires `evmVersion ≥ cancun` (needs `MCOPY`)
- **There is no valid compiler target that satisfies both.**

### 4. Possible Workarounds (Not Pursued)

| Approach | Trade-off |
|---|---|
| Downgrade to OpenZeppelin v4 | Loses latest security fixes, requires contract rewrites |
| Fork OZ v5 and remove `MCOPY` usage | Maintenance burden, diverges from upstream |
| Use inline assembly with pre-Cancun opcodes | Error-prone, defeats purpose of using audited libraries |
| Wait for Status Network EVM upgrade | Unknown timeline |

None of these were acceptable for a production governance system. Security of the contract library is non-negotiable.

### 5. Successful Deployment to Base Sepolia

We pivoted to Base Sepolia, which fully supports Cancun opcodes. The deployment succeeded:

| Contract | Address |
|---|---|
| **B4MAD Token** | [`0x0bb081b0769cd8211b6d316779a33D11D2F7900A`](https://sepolia.basescan.org/address/0x0bb081b0769cd8211b6d316779a33D11D2F7900A) |
| **TimelockController** | [`0xd3711fCbEE659dF6E830A523e14efC4b9c5F1279`](https://sepolia.basescan.org/address/0xd3711fCbEE659dF6E830A523e14efC4b9c5F1279) |
| **B4MADGovernor** | [`0x3D72176Bf9E921Db85170e3Cc3b40502f5a55281`](https://sepolia.basescan.org/address/0x3D72176Bf9E921Db85170e3Cc3b40502f5a55281) |

## Lessons Learned

### 1. zkEVM ≠ EVM

"EVM-compatible" is a spectrum, not a binary. Linea-based chains (including Status Network) lag behind mainnet EVM by multiple hard forks. Always verify the **exact EVM version** a chain supports before committing to a deployment target. Check for `PUSH0`, `MCOPY`, and other post-Shanghai opcodes.

### 2. OpenZeppelin v5 Has a Hard Floor

OpenZeppelin Contracts v5 is not backward-compatible with pre-Cancun EVMs. This is not documented prominently. If your target chain doesn't support Cancun, you're stuck on OZ v4 — which means older APIs, older security fixes, and eventual EOL.

### 3. "Gasless" Doesn't Mean "Easy to Deploy"

Status Network's gasless model is appealing for end users, but the developer experience for contract deployment is rough:
- The faucet requires 0.01 ETH on mainnet (chicken-and-egg for new deployers)
- The documentation has broken links and sparse Hardhat/Foundry guidance
- The EVM limitation isn't called out in their deployment tutorials

### 4. Hardhat 3 Breaking Changes

If you're upgrading from Hardhat 2, be aware:
- Network configs require `type: "http"` explicitly
- Artifact paths have changed — imported contract artifacts (e.g., OpenZeppelin's TimelockController) are no longer emitted as separate files
- Config is now TypeScript-first with stricter validation

### 5. Nonce Management on L2s

We hit multiple `nonce too low` and `replacement fee too low` errors on Base Sepolia. L2s process blocks fast and transactions can outpace the RPC's nonce tracking. Adding delays between transactions or using explicit nonce management is essential for multi-contract deployment scripts.

## Conclusion

Status Network has an interesting vision — gasless transactions and sustainable public funding for developers. But their current testnet infrastructure is not ready for modern Solidity contracts. Until they upgrade their EVM to at least Shanghai (ideally Cancun), deploying anything built with current tooling (OZ v5, Solidity ≥0.8.20) is not feasible.

We'll revisit Status Network when their EVM catches up. For now, **Base Sepolia** is our testnet home.

---

*This report is part of the [#B4mad DAO documentation](/docs/dao/). Source: [brenner-axiom/b4mad-dao-contracts](https://github.com/brenner-axiom/b4mad-dao-contracts).*
