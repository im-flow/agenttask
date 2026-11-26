# Agent ID Hackathon — Submission Draft (AgentTask)

Fill this into the Binance survey once the contract is deployed and live:
https://www.binance.com/en/survey/fb26d2bd25e04329b1ba77c7b3811d23
(Binance login required. One project per team. Deadline: 9 Dec 2026 08:00 UTC.)

## Project name

AgentTask

## Website

https://im-flow.github.io/agenttask/

## Repository (public, open source)

https://github.com/im-flow/agenttask

## Contract address (BNB Chain mainnet, chain id 56)

**Deployed 26 Nov 2026 23:51 WIB.**

- Contract: `0x2bc746b33fd36051d7a14725d83873a2e3ad5e12`
- Deploy tx: `0x1dd825afe321c31af2d3255e76546d35b2b70b4b33eae6d533a8719c12580309`
- Block: 135881655 · Deployer: `0x7477709e5ec51a1B49bab2777AF7F668aB016703` (MetaMask) · Fee: 0.0000959 BNB (1,918,624 gas @ 0.05 gwei)
- BscScan: https://bscscan.com/address/0x2bc746b33fd36051d7a14725d83873a2e3ad5e12
- Verified on-chain: code 8,628 bytes; `agentId()` = `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`; `CLAIM_TIMEOUT()` = 604800 (7 days); `MIN_REWARD()` = 0.001 BNB; `taskCount()` = 0.
- Source verification on BscScan: VERIFIED 26 Nov 23:55 WIB — "Exact Match", compiler v0.8.34+commit.80d5c536, optimization No with 200 runs, contract name AgentTask, constructor arg agentId_ = official contract.

## Agent ID usage description

AgentTask is a micro-bounty escrow that only Binance Agent ID holders
can use:

- **Access control** — `createTask()` and `claimTask()` both require
  `balanceOf(msg.sender) > 0` on the official Agent ID contract
  (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID ERC-721,
  non-transferable). Without an Agent ID, no interaction is possible.
- **Identity** — posters and workers are Agent ID holders by
  construction; the frontend shows each party's holder status checked
  on-chain.
- **One person, one account** — each person can hold only one
  non-transferable Agent ID, so task claims cannot be multiplied with
  throwaway wallets.

## What it does

A poster locks BNB in escrow for a small task (minimum 0.001 BNB).
Another Agent ID holder claims it. When the poster confirms the work,
the contract pays the worker; if the task is never claimed, the poster
cancels and is refunded in full. A claimed task has a 7-day deadline:
if the worker does not deliver in time, the poster can cancel and be
refunded instead of the escrow locking forever; a late completion is
still payable if the poster confirms it before cancelling. No owner, no
admin functions, no fees, no scheduled or bundled transfers — every
movement is an explicit user-signed transaction.

## Reward receiving address (suggested — user confirms)

`0x0189defb804ae790ABeFeeEA1f4580dd896e137C` (Binance Agentic Wallet,
Agent ID xflow.ai)

## Status checklist (before submitting)

- [x] Contract deployed on BNB Chain mainnet
- [x] Source verified + open on BscScan
- [x] `CONTRACT_ADDRESS` filled in `docs/app.js`, site re-checked live
- [ ] At least 30 distinct Agent ID addresses interacted with the contract
- [x] This draft's TBD fields filled in
- [ ] Survey submitted by the user (Binance login) before 9 Dec 2026 15:00 WIB
