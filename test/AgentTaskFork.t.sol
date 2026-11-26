// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AgentTask.sol";

/// @notice Fork test against the REAL Agent ID contract on BNB Chain.
///  Run: forge test --match-contract AgentTaskForkTest \
///         --fork-url https://bsc-dataseed1.bnbchain.org
///  No mainnet state is changed: everything runs on the fork.
contract AgentTaskForkTest is Test {
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    // The user's Agentic Wallet (xflow.ai) — must hold an Agent ID.
    address constant USER_WALLET = 0x0189defb804ae790ABeFeeEA1f4580dd896e137C;
    // A second, independent Agent ID holder (OneVoice author, public README).
    address constant OTHER_HOLDER = 0xfBcE2E2D17F7C89CaA567B50Cd5f98570F7fFd5D;

    AgentTask public task;

    function setUp() public {
        task = new AgentTask(AGENT_ID);
        vm.deal(USER_WALLET, 1 ether);
        vm.deal(OTHER_HOLDER, 1 ether);
    }

    function testRealAgentIdHeldByUser() public view {
        assertGt(IAgentID(AGENT_ID).balanceOf(USER_WALLET), 0, "user wallet holds no Agent ID");
        assertGt(IAgentID(AGENT_ID).balanceOf(OTHER_HOLDER), 0, "other holder has no Agent ID");
    }

    function testFullFlowAgainstRealAgentId() public {
        vm.prank(USER_WALLET);
        uint256 id = task.createTask{value: 0.05 ether}("Fork test task", "created on a mainnet fork");
        assertEq(task.taskCount(), 1);

        vm.prank(OTHER_HOLDER);
        task.claimTask(id);

        uint256 before_ = OTHER_HOLDER.balance;
        vm.prank(USER_WALLET);
        task.completeTask(id);
        assertEq(OTHER_HOLDER.balance, before_ + 0.05 ether);
        assertEq(uint8(task.getTask(id).status), uint8(AgentTask.Status.Completed));
    }
}
