// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentTask — micro-bounty escrow for Binance Agent ID holders
/// @notice Posters lock BNB in escrow for a small task. Only holders of a
///  Binance Agent ID (.ai, non-transferable ERC-721) can create, claim, or
///  be paid for tasks. The poster releases the escrow by confirming
///  completion; an unclaimed task can be cancelled for a full refund.
///  A claimed task has a 7-day deadline: if the worker does not deliver
///  in time, the poster can cancel and be refunded instead of the escrow
///  locking forever.
/// @dev No owner, no admin functions, no upgradeability, no fees.
///  Every state-changing function is an explicit user-signed transaction:
///  there are no scheduled transfers, no bundled transfers, and no
///  approvals. Agent ID is checked on-chain via balanceOf on the official
///  SPACE ID Agent ID contract (0x60b9262456de011f7d15a54cdd8c48baaa8b022f).
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentTask {
    IAgentID public immutable agentId;

    /// @notice Minimum escrow so tasks are real and spam is uneconomic.
    uint256 public constant MIN_REWARD = 0.001 ether;

    /// @notice How long a worker has to deliver after claiming, before
    ///  the poster can cancel and reclaim the escrow.
    uint256 public constant CLAIM_TIMEOUT = 7 days;

    enum Status {
        Open,
        Claimed,
        Completed,
        Cancelled
    }

    struct Task {
        address poster;
        address worker;
        uint256 reward;
        Status status;
        string title;
        string details;
        uint256 claimedAt;
    }

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 indexed id, address indexed poster, uint256 reward, string title);
    event TaskClaimed(uint256 indexed id, address indexed worker);
    event TaskCompleted(uint256 indexed id, address indexed worker, uint256 reward);
    event TaskCancelled(uint256 indexed id, address indexed poster);

    bool private locked;

    modifier onlyAgentId() {
        require(agentId.balanceOf(msg.sender) > 0, "AgentTask: Agent ID required");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "AgentTask: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor(address agentId_) {
        require(agentId_ != address(0), "AgentTask: zero Agent ID address");
        agentId = IAgentID(agentId_);
    }

    /// @notice Create a task and lock its BNB reward in escrow.
    function createTask(string calldata title, string calldata details) external payable onlyAgentId returns (uint256 id) {
        require(msg.value >= MIN_REWARD, "AgentTask: reward below minimum");
        require(bytes(title).length > 0, "AgentTask: empty title");
        id = taskCount;
        tasks[id] = Task({
            poster: msg.sender,
            worker: address(0),
            reward: msg.value,
            status: Status.Open,
            title: title,
            details: details,
            claimedAt: 0
        });
        taskCount = id + 1;
        emit TaskCreated(id, msg.sender, msg.value, title);
    }

    /// @notice Claim an open task. The poster cannot claim their own task.
    function claimTask(uint256 id) external onlyAgentId {
        Task storage t = tasks[id];
        require(t.status == Status.Open, "AgentTask: task not open");
        require(msg.sender != t.poster, "AgentTask: poster cannot claim");
        t.worker = msg.sender;
        t.status = Status.Claimed;
        t.claimedAt = block.timestamp;
        emit TaskClaimed(id, msg.sender);
    }

    /// @notice Poster confirms the work is done; escrow pays the worker.
    function completeTask(uint256 id) external nonReentrant {
        Task storage t = tasks[id];
        require(msg.sender == t.poster, "AgentTask: only poster");
        require(t.status == Status.Claimed, "AgentTask: task not claimed");
        t.status = Status.Completed;
        uint256 reward = t.reward;
        address worker = t.worker;
        emit TaskCompleted(id, worker, reward);
        (bool ok, ) = worker.call{value: reward}("");
        require(ok, "AgentTask: payout failed");
    }

    /// @notice Poster cancels an unclaimed task, or a claimed task whose
    ///  worker missed the 7-day deadline; escrow refunds in full.
    ///  A late completion is still payable if the poster confirms it
    ///  before cancelling.
    function cancelTask(uint256 id) external nonReentrant {
        Task storage t = tasks[id];
        require(msg.sender == t.poster, "AgentTask: only poster");
        if (t.status == Status.Claimed) {
            require(block.timestamp >= t.claimedAt + CLAIM_TIMEOUT, "AgentTask: claim not expired");
        } else {
            require(t.status == Status.Open, "AgentTask: task not open");
        }
        t.status = Status.Cancelled;
        uint256 reward = t.reward;
        address poster = t.poster;
        emit TaskCancelled(id, poster);
        (bool ok, ) = poster.call{value: reward}("");
        require(ok, "AgentTask: refund failed");
    }

    function getTask(uint256 id) external view returns (Task memory) {
        return tasks[id];
    }
}
