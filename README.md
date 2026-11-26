# AgentTask

Micro-bounty escrow for Binance Agent ID holders, on BNB Chain.

Posters lock BNB in escrow for a small task. Only holders of a Binance
Agent ID (`.ai`, non-transferable ERC-721) can create tasks, claim them,
or be paid for them. The poster releases the escrow by confirming the
work is done; an unclaimed task can be cancelled for a full refund.

Built for the **Binance Wallet x BNB Chain Agent ID Hackathon**
(60,000 USDC prize pool, submissions until 9 Dec 2026 08:00 UTC).

## How Agent ID is used

- **Access control** — `createTask`, `claimTask` (and therefore every
  payout) require `balanceOf(msg.sender) > 0` on the official Agent ID
  contract (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID
  ERC-721, non-transferable). No Agent ID, no interaction.
- **Identity** — posters and workers are Agent ID holders; the frontend
  shows the holder's address and on-chain holder status.
- **One person, one account** — each person can hold only one
  non-transferable Agent ID, so task claims can't be multiplied with
  throwaway wallets.

## Contract

- `src/AgentTask.sol` — the escrow. No owner, no admin functions, no
  upgradeability, no fees. Every transfer is an explicit user-signed
  transaction (poster creates, worker claims, poster confirms →
  payout; poster cancels → refund). No scheduled transfers, no bundled
  transfers, no approvals beyond the single escrow deposit.
- Minimum reward: 0.001 BNB. **Claim timeout: 7 days** — if a worker
  claims a task and does not deliver in time, the poster can cancel
  and be refunded instead of the escrow locking forever. A late
  completion is still payable if the poster confirms it before
  cancelling.
- Status: `Open → Claimed → Completed` (paid) or `Open → Cancelled`
  (refunded, including timeout-cancel after 7 days).

**Deployment:** BNB Chain mainnet (chain id 56). Contract address:
_TBD — deploying next._

## Development

```bash
forge test          # 12 unit tests (mock Agent ID)
forge test --match-contract AgentTaskForkTest \
  --fork-url https://bsc-dataseed1.bnbchain.org   # 2 tests vs the real Agent ID contract
```

Deploy (the deployer signs in their own wallet):

```bash
forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed1.bnbchain.org --broadcast
```

Then verify the source on BscScan and put the address in
`docs/app.js` (`CONTRACT_ADDRESS`).

## Website

`docs/` is a static page (GitHub Pages). It connects to the user's own
injected wallet (MetaMask / Binance Wallet extension) — no QR login,
no session storage, no keys ever touch the page.

## Hackathon

- Announcement: https://www.binance.com/en/square/post/389517345917641
- Submission: Binance survey (login required),
  https://www.binance.com/en/survey/fb26d2bd25e04329b1ba77c7b3811d23
- Target award: Agent Application Innovation Award (judged: 30% Agent ID
  depth, 25% practicality, 25% completion, 20% innovation). Eligibility:
  live product + at least 30 Agent ID addresses interacting during the
  submission period.
