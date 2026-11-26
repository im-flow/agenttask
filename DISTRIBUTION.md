# AgentTask — Distribution plan (30 Agent ID addresses)

Goal: at least **30 distinct Agent ID addresses interacting** with the
AgentTask contract during the submission period (Innovation Award
eligibility). Reality check from Binance's Week 1 update (26 Nov 2026):
**400+ projects submitted, 62,000+ Agent ID addresses already
interacting** — 30 is the floor, not the differentiator. The escrow
mechanic is what makes us stand out; distribution is what makes us
counted.

## X announcement (DRAFT — do NOT post before deploy)

The site currently says "not deployed yet". Post this only once the
contract is live and `CONTRACT_ADDRESS` is filled in `docs/app.js`.

> AgentTask is live: micro-bounties with BNB escrow, only for Agent ID holders. Post a task, lock the reward, get it done. No middleman, no fees. https://im-flow.github.io/agenttask #BinanceWalletHackathon #AgenticWallet
> (218 characters — fits in one post. No promises of returns, no
> "passive income" language, per the hackathon rules.)

Bonus: the same post can be entered into the **Community Promotion
Award** (2,000 USDC shared by 20 winners for original X posts about
participating projects, using the two hashtags above) — submit the post
link via the official campaign survey linked in the announcement.

## Channels (only what was verified to exist, 26 Nov 2026)

1. **X** — hashtags `#BinanceWalletHackathon` and `#AgenticWallet`
   (official tags from the Binance announcement; @BinanceWallet posted
   the launch there). Primary channel.
2. **Binance Square** — comment/reply on the official announcement
   post (binance.com/en/square/post/389517345917641) and the Week 1
   update post. Public discussion, holders read it.
3. **The Colony** (thecolony.ai / thecolony.cc) — publish a project
   update post, the way GLOOP and SYMPHONY did.
4. **Boltbook** (boltbook.fun) — agent project directory where
   AgentQuest and Agentic are listed. Check how a listing is added
   (entries show "Submitted by <agent>.ai"); list AgentTask if the
   route is open.
5. **Telegram @binance_wallet_announcements** (23k subscribers) —
   official broadcast channel. Follow it for Week 2/3 updates and the
   top-20 lists. You cannot post there (broadcast only).

**NOT found — do not assume they exist:** no dedicated Discord or
Telegram group for the hackathon turned up in search, and the Agent
Roll Call site (faisalandri893.github.io/agent-roll-call) has no public
community links — it is a dApp only. Do not invent a group or quote a
Discord invite that was never verified.

## Launch-day checklist (in order)

- [ ] Decide: upgrade contract (add claim timeout) vs deploy as-is
      (pending with the user — do NOT deploy before this is decided)
- [ ] Deploy via Remix + MetaMask (baw cannot deploy contracts)
- [ ] Verify source on BscScan
- [ ] Fill `CONTRACT_ADDRESS` in `docs/app.js` and in
      `SUBMISSION-DRAFT.md`; push; re-check Pages returns 200
- [ ] Seed 2–3 small bait tasks from xflow.ai (0.001–0.01 BNB each)
      so the first claimers pay only gas — see ideas below
- [ ] Post the X announcement above (only now that the site is live)
- [ ] Submit the X post link to the Community Promotion Award survey
- [ ] Comment on the Binance Square announcement post
- [ ] Publish an update on The Colony
- [ ] Monitor unique interacting addresses daily (command below);
      target 30, then keep going — Pioneer Award ranks by on-chain
      activity, so more is better
- [ ] Submit the project via the Binance survey before
      9 Dec 2026 15:00 WIB

## Seed-task ideas (post these yourself right after deploy)

- "Translate the AgentTask README to Indonesian" — 0.005 BNB
- "Try AgentTask end to end and write a 1-paragraph review" — 0.002 BNB
- "Report a UI bug with a screenshot" — 0.003 BNB

## Monitoring: count unique interacting Agent ID addresses

Every address that appears as poster in `TaskCreated` or worker in
`TaskClaimed` holds an Agent ID by contract enforcement, so the count
of distinct addresses across those two events IS the Agent ID count.

```bash
# <CONTRACT> = deployed address, <DEPLOY_BLOCK> = deploy block number
cast logs --rpc-url https://bsc-dataseed1.bnbchain.org \
  --from-block <DEPLOY_BLOCK> --address <CONTRACT> --json \
  | jq -r 'select(.topics[0] == "0xedce45cc3fc2bea98c94b72104f4a750dcc91bd183a01870ed4f93a365eba5b9"
        or .topics[0] == "0x1d8996e29d44a50435d568c283ce2580e5706f87b19ff3d34f455c9d2a994620")
        | .topics[2]' | sort -u | wc -l
# topic0 values: TaskCreated = 0xedce…a5b9, TaskClaimed = 0x1d89…4620
# topics[2] = poster (TaskCreated) / worker (TaskClaimed)
```
