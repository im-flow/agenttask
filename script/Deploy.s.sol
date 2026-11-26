// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgentTask.sol";

/// @notice Deploy AgentTask to BNB Chain (mainnet chain id 56).
///  The Agent ID address is the official SPACE ID Agent ID contract.
///  Run: forge script script/Deploy.s.sol --rpc-url <bsc-rpc> --broadcast
///  Broadcasting needs the deployer's key — the user signs the deploy
///  themselves (or via their reconnected Agentic Wallet).
contract Deploy is Script {
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external returns (AgentTask) {
        vm.startBroadcast();
        AgentTask task = new AgentTask(AGENT_ID);
        vm.stopBroadcast();
        console.log("AgentTask deployed at:", address(task));
        console.log("Agent ID contract:", AGENT_ID);
        return task;
    }
}
