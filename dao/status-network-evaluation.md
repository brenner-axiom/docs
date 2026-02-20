---
layout: page
title: "Status Network Evaluation"
permalink: /docs/dao/status-network-evaluation
---

# Status Network Evaluation for B4MAD DAO

**Date:** 2026-02-20
**Bead:** beads-hub-607 — "DAO Phase 2: Extend to Status Network (gasless L2)"
**Status:** Evaluation complete — prep work done, not yet deployed

## Network Details

| Property | Value |
|---|---|
| Network Name | Status Network Testnet |
| Chain ID | 1660990954 (0x6300b5ea) |
| RPC Endpoint | https://public.sepolia.rpc.status.network |
| Currency Symbol | ETH |
| Block Explorer | https://sepoliascan.status.network |
| Bridge | https://bridge.status.network |
| WebSocket RPC | Contact Status team on Telegram |
| Stack | Linea zkEVM rollup (L2 on Sepolia) |

## Faucet Info

- **ETH Faucet:** https://faucet.status.network — 0.01 ETH/day, requires 0.01 ETH on mainnet
- **STT (test SNT) Faucet:** https://hub.status.network/stake — 10,000 STT/day
- **Alternative:** Bridge Sepolia ETH via https://bridge.status.network

## EVM Compatibility Assessment

**Verdict: COMPATIBLE ✅**

- Built on Linea zkEVM stack — full EVM bytecode compatibility
- Solidity 0.8.20 and 0.8.28 both supported (docs show `^0.8.24` in examples)
- Standard EVM opcodes supported; Linea zkEVM has minor limitations on some precompiles but nothing affecting our contracts (B4MAD.sol, MyVestingWallet.sol)
- Hardhat + ethers.js deployment workflow works (confirmed by their docs)

## Aragon OSx Support

**Verdict: NOT SUPPORTED ❌**

Aragon OSx does **not** have official deployments on Status Network. This means:
- No pre-deployed DAOFactory, PluginRepoFactory, etc.
- We would need to deploy the full Aragon OSx framework ourselves (complex, not recommended)
- **Recommendation:** Use our own lightweight DAO contracts (B4MAD.sol) instead of Aragon OSx on Status Network, OR wait for Aragon to add support

## Pros vs Base (Sepolia)

| Factor | Status Network | Base Sepolia |
|---|---|---|
| **Gas fees** | Gasless (zero gas for users) ✅ | Low but non-zero |
| **User onboarding** | No gas needed = frictionless ✅ | Need to acquire ETH first |
| **Spam protection** | RLN (rate-limiting nullifiers) ✅ | Standard gas-based |
| **Aragon OSx** | Not supported ❌ | Supported ✅ |
| **Ecosystem maturity** | Very early, small ecosystem ⚠️ | Large, established ✅ |
| **Block explorer** | Basic (Blockscout-based) | Robust (Basescan) |
| **Developer tooling** | Minimal, growing | Extensive |
| **Native integrations** | Status Wallet, Keycard, Waku | Coinbase Wallet |
| **Public funding model** | Native yield + DEX fees → builder funding ✅ | None built-in |
| **Target audience** | Social apps & games | General purpose |

## Cons / Risks

1. **No Aragon OSx** — must use custom DAO contracts or deploy Aragon framework ourselves
2. **Early stage** — testnet only info available, mainnet details TBD
3. **Small ecosystem** — fewer users, fewer composable protocols
4. **Faucet requires mainnet ETH** — 0.01 ETH on mainnet to use faucet
5. **WebSocket RPC not publicly available** — need to contact team
6. **Unknown block finality characteristics** — zkEVM proving times may vary

## Deployment Readiness Checklist

- [x] Network details documented
- [x] Hardhat config added (`statusTestnet` network in hardhat.config.js)
- [x] EVM compatibility confirmed
- [ ] Aragon OSx support — **NOT AVAILABLE** (blocker for Aragon-based DAO)
- [ ] Testnet ETH acquired (faucet requires 0.01 mainnet ETH — needs manual step)
- [ ] Contract compilation tested on Status Network
- [ ] Contract deployment tested
- [ ] Block explorer verification workflow tested

## Recommendation

**Status Network is a strong candidate for Phase 2** due to gasless transactions, which aligns perfectly with a community DAO where we don't want members to worry about gas. However, the lack of Aragon OSx support is a significant consideration.

**Recommended approach:**
1. Complete Phase 1 on Base Sepolia with Aragon OSx
2. Deploy our custom B4MAD.sol contracts (non-Aragon) on Status Network testnet as a parallel experiment
3. Monitor Status Network ecosystem growth and Aragon support
4. If gasless UX proves valuable, consider Status Network for mainnet DAO

## Changes Made

- Added `statusTestnet` network config to `hardhat.config.js` in b4mad-dao-contracts
- Created this evaluation document
