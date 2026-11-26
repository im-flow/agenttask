// AgentTask frontend — static page, injected wallet only (no QR login,
// no session storage). Reads via a public BSC RPC; writes go through the
// user's own wallet as explicit signed transactions.
"use strict";

var CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000"; // TODO: fill after mainnet deploy
var AGENT_ID_ADDRESS = "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F";
var BSC_CHAIN_ID = 56;
var BSC_RPC = "https://bsc-dataseed1.bnbchain.org";
var BSCSCAN = "https://bscscan.com/address/";
// Must match CLAIM_TIMEOUT in AgentTask.sol (7 days).
var CLAIM_TIMEOUT_SECONDS = 7 * 24 * 3600;

var AGENT_ID_ABI = ["function balanceOf(address owner) view returns (uint256)"];
var TASK_ABI = [
  "function taskCount() view returns (uint256)",
  "function getTask(uint256 id) view returns (tuple(address poster, address worker, uint256 reward, uint8 status, string title, string details, uint256 claimedAt))",
  "function createTask(string title, string details) payable returns (uint256)",
  "function claimTask(uint256 id)",
  "function completeTask(uint256 id)",
  "function cancelTask(uint256 id)",
  "function MIN_REWARD() view returns (uint256)"
];

var STATUS = ["Open", "Claimed", "Completed", "Cancelled"];
var readProvider = new ethers.JsonRpcProvider(BSC_RPC);
var signer = null;
var userAddress = null;

function $(id) { return document.getElementById(id); }
function short(addr) { return addr ? addr.slice(0, 6) + "…" + addr.slice(-4) : ""; }
function setStatus(msg, isError, txHash) {
  var el = $("status");
  el.textContent = msg || "";
  el.style.color = isError ? "#a33" : "";
  if (txHash) {
    var a = document.createElement("a");
    a.href = "https://bscscan.com/tx/" + txHash;
    a.target = "_blank";
    a.rel = "noopener";
    a.textContent = "Lihat di BscScan";
    el.appendChild(document.createTextNode(" "));
    el.appendChild(a);
  }
}

function escrowDeployed() {
  return CONTRACT_ADDRESS && CONTRACT_ADDRESS !== "0x0000000000000000000000000000000000000000";
}

async function refreshWalletInfo() {
  if (!userAddress) {
    $("wallet-info").textContent = "Wallet not connected.";
    $("agent-status").textContent = "";
    return;
  }
  $("wallet-info").textContent = "Connected: " + userAddress;
  try {
    var agent = new ethers.Contract(AGENT_ID_ADDRESS, AGENT_ID_ABI, readProvider);
    var bal = await agent.balanceOf(userAddress);
    $("agent-status").textContent = bal > 0n
      ? "✓ This wallet holds a Binance Agent ID — you can post and claim tasks."
      : "✗ This wallet holds no Agent ID. Claim one in the Binance app (Wallet > Agent ID) to use AgentTask.";
  } catch (e) {
    $("agent-status").textContent = "Could not check Agent ID status: " + (e && e.message ? e.message : e);
  }
}

async function connect() {
  if (!window.ethereum) {
    setStatus("No wallet found in this browser. Install MetaMask or the Binance Wallet extension, then try again.", true);
    return;
  }
  try {
    var provider = new ethers.BrowserProvider(window.ethereum);
    var network = await provider.getNetwork();
    if (Number(network.chainId) !== BSC_CHAIN_ID) {
      try {
        await window.ethereum.request({ method: "wallet_switchEthereumChain", params: [{ chainId: "0x38" }] });
      } catch (switchErr) {
        setStatus("Please switch your wallet to BNB Chain (chain id 56).", true);
        return;
      }
    }
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();
    setStatus("Connected as " + short(userAddress) + ".");
    await refreshWalletInfo();
    await loadTasks();
  } catch (e) {
    setStatus("Connection failed: " + (e && e.message ? e.message : e), true);
  }
}

function taskCard(t, id) {
  var div = document.createElement("div");
  div.className = "card";
  var head = document.createElement("div");
  var badge = document.createElement("span");
  badge.className = "badge " + STATUS[t.status].toLowerCase();
  badge.textContent = STATUS[t.status];
  var title = document.createElement("strong");
  title.textContent = " #" + id + " " + t.title;
  head.appendChild(badge);
  head.appendChild(title);
  var meta = document.createElement("div");
  meta.className = "meta";
  meta.textContent = "Reward: " + ethers.formatEther(t.reward) + " BNB · Poster: " + short(t.poster) +
    (t.worker !== "0x0000000000000000000000000000000000000000" ? " · Worker: " + short(t.worker) : "") +
    (t.status === 1 && t.claimedAt ? " · Complete by " + new Date((t.claimedAt + CLAIM_TIMEOUT_SECONDS) * 1000).toLocaleDateString() : "");
  var details = document.createElement("div");
  details.textContent = t.details;
  div.appendChild(head);
  div.appendChild(meta);
  div.appendChild(details);

  if (escrowDeployed() && userAddress) {
    var mine = userAddress.toLowerCase();
    if (t.status === 0 && t.poster.toLowerCase() !== mine) {
      var claim = document.createElement("button");
      claim.textContent = "Claim this task";
      claim.onclick = function () { sendTx("claimTask", [id], "Claimed task #" + id + "."); };
      div.appendChild(claim);
    }
    if (t.status === 1 && t.poster.toLowerCase() === mine) {
      var done = document.createElement("button");
      done.textContent = "Confirm done & pay worker";
      done.className = "primary";
      done.onclick = function () { sendTx("completeTask", [id], "Task #" + id + " completed — worker paid."); };
      div.appendChild(done);
    }
    if (t.status === 1 && t.poster.toLowerCase() === mine) {
      var cancelClaimed = document.createElement("button");
      var deadline = new Date((t.claimedAt + CLAIM_TIMEOUT_SECONDS) * 1000);
      var expired = Date.now() >= deadline.getTime();
      cancelClaimed.textContent = expired ? "Cancel (worker timed out) & refund" : "Cancel & refund after " + deadline.toLocaleDateString();
      cancelClaimed.disabled = !expired;
      cancelClaimed.onclick = function () { sendTx("cancelTask", [id], "Task #" + id + " cancelled — refunded."); };
      div.appendChild(cancelClaimed);
    }
    if (t.status === 0 && t.poster.toLowerCase() === mine) {
      var cancel = document.createElement("button");
      cancel.textContent = "Cancel & refund";
      cancel.onclick = function () { sendTx("cancelTask", [id], "Task #" + id + " cancelled — refunded."); };
      div.appendChild(cancel);
    }
  }
  return div;
}

async function loadTasks() {
  var box = $("tasks");
  if (!escrowDeployed()) {
    box.innerHTML = "";
    var p = document.createElement("p");
    p.className = "muted";
    p.textContent = "The contract is not deployed yet — tasks will appear here once it is live on BNB Chain.";
    box.appendChild(p);
    return;
  }
  try {
    var c = new ethers.Contract(CONTRACT_ADDRESS, TASK_ABI, readProvider);
    var count = Number(await c.taskCount());
    box.innerHTML = "";
    if (count === 0) {
      var empty = document.createElement("p");
      empty.className = "muted";
      empty.textContent = "No tasks yet. Be the first to post one.";
      box.appendChild(empty);
      return;
    }
    var start = Math.max(0, count - 50);
    for (var id = count - 1; id >= start; id--) {
      var t = await c.getTask(id);
      box.appendChild(taskCard({ poster: t[0], worker: t[1], reward: t[2], status: Number(t[3]), title: t[4], details: t[5], claimedAt: Number(t[6]) }, id));
    }
  } catch (e) {
    box.innerHTML = "";
    var err = document.createElement("p");
    err.className = "muted";
    err.textContent = "Could not load tasks: " + (e && e.message ? e.message : e);
    box.appendChild(err);
  }
}

async function sendTx(method, args, okMsg) {
  if (!signer) { setStatus("Connect your wallet first.", true); return; }
  try {
    setStatus("Waiting for your signature in the wallet…");
    var c = new ethers.Contract(CONTRACT_ADDRESS, TASK_ABI, signer);
    var tx = await c[method](...args);
    setStatus("Transaction sent — waiting for confirmation…", false, tx.hash);
    await tx.wait();
    setStatus(okMsg, false, tx.hash);
    await loadTasks();
  } catch (e) {
    setStatus("Transaction failed: " + (e && e.reason ? e.reason : (e && e.message ? e.message : e)), true);
  }
}

async function createTask() {
  if (!escrowDeployed()) { setStatus("The contract is not deployed yet — check back soon.", true); return; }
  if (!signer) { setStatus("Connect your wallet first.", true); return; }
  var title = $("title").value.trim();
  var details = $("details").value.trim();
  var reward = $("reward").value.trim();
  if (!title) { setStatus("Give the task a title.", true); return; }
  if (!reward || Number(reward) < 0.001) { setStatus("Reward must be at least 0.001 BNB.", true); return; }
  try {
    setStatus("Waiting for your signature in the wallet…");
    var c = new ethers.Contract(CONTRACT_ADDRESS, TASK_ABI, signer);
    var tx = await c.createTask(title, details, { value: ethers.parseEther(reward) });
    setStatus("Transaction sent — waiting for confirmation…", false, tx.hash);
    await tx.wait();
    setStatus("Task posted — " + reward + " BNB locked in escrow.", false, tx.hash);
    $("title").value = ""; $("details").value = ""; $("reward").value = "";
    await loadTasks();
  } catch (e) {
    setStatus("Transaction failed: " + (e && e.reason ? e.reason : (e && e.message ? e.message : e)), true);
  }
}

$("connect-btn").addEventListener("click", connect);
$("create-btn").addEventListener("click", createTask);
if (window.ethereum) {
  window.ethereum.on("accountsChanged", function () { location.reload(); });
  window.ethereum.on("chainChanged", function () { location.reload(); });
}
$("contract-addr").textContent = escrowDeployed() ? CONTRACT_ADDRESS : "not deployed yet";
$("contract-link").href = BSCSCAN + (escrowDeployed() ? CONTRACT_ADDRESS : AGENT_ID_ADDRESS);
loadTasks();
refreshWalletInfo();
