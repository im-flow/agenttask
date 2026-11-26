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

**TBD — deploy pending.** (Agentic Wallet reconnected 26 Nov 23:27 WIB;
deploy gas ~0.00007 BNB is covered by the 0.000525 BNB balance, no top-up
needed. Deploy via Remix + MetaMask — baw cannot deploy contracts. After
deploy, verify source on BscScan and fill the address here + in `docs/app.js`.)

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

- [ ] Contract deployed on BNB Chain mainnet
- [ ] Source verified + open on BscScan
- [ ] `CONTRACT_ADDRESS` filled in `docs/app.js`, site re-checked live
- [ ] At least 30 distinct Agent ID addresses interacted with the contract
- [ ] This draft's TBD fields filled in
- [ ] Survey submitted by the user (Binance login) before 9 Dec 2026 15:00 WIB
