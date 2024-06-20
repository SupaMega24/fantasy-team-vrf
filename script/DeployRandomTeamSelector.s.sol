// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {RandomTeamSelector} from "../src/RandomTeamSelector.sol";

contract DeployRandomTeamSelector is Script {
    function run() external returns (RandomTeamSelector, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 subId,
            address vrfCoordinator,
            bytes32 gasLane,
            uint32 gasLimit,
            uint16 requestConfirmations,
            uint32 numWords,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        RandomTeamSelector randomTeamSelector = new RandomTeamSelector(
            vrfCoordinator,
            subId,
            gasLane,
            gasLimit,
            requestConfirmations,
            numWords
        );
        vm.stopBroadcast();

        return (randomTeamSelector, helperConfig);
    }
}
