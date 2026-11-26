// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AgentTask.sol";

/// @notice Minimal stand-in for the SPACE ID Agent ID ERC-721.
contract MockAgentID {
    mapping(address => uint256) private _balances;

    function mint(address to) external {
        _balances[to] = 1;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}

contract AgentTaskTest is Test {
    AgentTask public task;
    MockAgentID public agentId;

    address public poster = address(0xA11CE);
    address public worker = address(0xB0B);
    address public stranger = address(0xCAFE);

    function setUp() public {
        agentId = new MockAgentID();
        agentId.mint(poster);
        agentId.mint(worker);
        task = new AgentTask(address(agentId));
        vm.deal(poster, 10 ether);
        vm.deal(worker, 10 ether);
        vm.deal(stranger, 10 ether);
    }

    function _createTask() internal returns (uint256 id) {
        vm.prank(poster);
        id = task.createTask{value: 0.05 ether}("Translate a README", "EN to ID, ~300 words");
    }

    function testCreateRequiresAgentId() public {
        vm.prank(stranger);
        vm.expectRevert("AgentTask: Agent ID required");
        task.createTask{value: 0.05 ether}("x", "y");
    }

    function testCreateBelowMinimumReverts() public {
        vm.prank(poster);
        vm.expectRevert("AgentTask: reward below minimum");
        task.createTask{value: 0.0005 ether}("x", "y");
    }

    function testCreateStoresTask() public {
        uint256 id = _createTask();
        assertEq(id, 0);
        assertEq(task.taskCount(), 1);
        AgentTask.Task memory t = task.getTask(0);
        assertEq(t.poster, poster);
        assertEq(t.reward, 0.05 ether);
        assertEq(uint8(t.status), uint8(AgentTask.Status.Open));
        assertEq(t.title, "Translate a README");
    }

    function testClaimRequiresAgentId() public {
        _createTask();
        vm.prank(stranger);
        vm.expectRevert("AgentTask: Agent ID required");
        task.claimTask(0);
    }

    function testClaimOwnTaskReverts() public {
        _createTask();
        vm.prank(poster);
        vm.expectRevert("AgentTask: poster cannot claim");
        task.claimTask(0);
    }

    function testClaimTwiceReverts() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        vm.prank(worker);
        vm.expectRevert("AgentTask: task not open");
        task.claimTask(0);
    }

    function testCompletePaysWorker() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        uint256 before_ = worker.balance;
        vm.prank(poster);
        task.completeTask(0);
        assertEq(worker.balance, before_ + 0.05 ether);
        assertEq(address(task).balance, 0);
        assertEq(uint8(task.getTask(0).status), uint8(AgentTask.Status.Completed));
    }

    function testCompleteOnlyPoster() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        vm.prank(worker);
        vm.expectRevert("AgentTask: only poster");
        task.completeTask(0);
    }

    function testCompleteUnclaimedReverts() public {
        _createTask();
        vm.prank(poster);
        vm.expectRevert("AgentTask: task not claimed");
        task.completeTask(0);
    }

    function testCancelRefundsPoster() public {
        _createTask();
        uint256 before_ = poster.balance;
        vm.prank(poster);
        task.cancelTask(0);
        assertEq(poster.balance, before_ + 0.05 ether);
        assertEq(uint8(task.getTask(0).status), uint8(AgentTask.Status.Cancelled));
    }

    function testCancelClaimedReverts() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        vm.prank(poster);
        vm.expectRevert("AgentTask: claim not expired");
        task.cancelTask(0);
    }

    function testCancelOnlyPoster() public {
        _createTask();
        vm.prank(worker);
        vm.expectRevert("AgentTask: only poster");
        task.cancelTask(0);
    }

    function testClaimSetsClaimedAt() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        assertEq(task.getTask(0).claimedAt, block.timestamp);
        assertEq(task.CLAIM_TIMEOUT(), 7 days);
    }

    function testCancelClaimedBeforeTimeoutReverts() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        vm.warp(block.timestamp + task.CLAIM_TIMEOUT() - 1);
        vm.prank(poster);
        vm.expectRevert("AgentTask: claim not expired");
        task.cancelTask(0);
    }

    function testCancelClaimedAfterTimeoutRefunds() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        vm.warp(block.timestamp + task.CLAIM_TIMEOUT() + 1);
        uint256 before_ = poster.balance;
        vm.prank(poster);
        task.cancelTask(0);
        assertEq(poster.balance, before_ + 0.05 ether);
        assertEq(address(task).balance, 0);
        assertEq(uint8(task.getTask(0).status), uint8(AgentTask.Status.Cancelled));
    }

    function testCompleteAfterTimeoutStillPays() public {
        _createTask();
        vm.prank(worker);
        task.claimTask(0);
        vm.warp(block.timestamp + task.CLAIM_TIMEOUT() + 1);
        uint256 before_ = worker.balance;
        vm.prank(poster);
        task.completeTask(0);
        assertEq(worker.balance, before_ + 0.05 ether);
        assertEq(uint8(task.getTask(0).status), uint8(AgentTask.Status.Completed));
    }
}
