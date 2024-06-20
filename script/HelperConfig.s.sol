// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 subId;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 gasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    /**
     * @dev the Chainlink VRF V2.5 values of the NetworkConfig below are of Sepolia.
     * @notice you can get your own values and other networks here
     *         https://docs.chain.link/vrf/v2-5/supported-networks#overview
     */

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                subId: vm.envUint("SUBSCRIPTION_ID"),
                vrfCoordinator: vm.envAddress("VRFCOORDINATOR_ADDRESS"),
                gasLane: vm.envBytes32("KEY_HASH"),
                gasLimit: uint32(vm.envUint("CALLBACK_GAS_LIMIT")),
                requestConfirmations: uint16(
                    vm.envUint("REQUEST_CONFIRMATIONS")
                ),
                numWords: uint32(vm.envUint("NUMBER_OF_WORDS")),
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 1e18; // 1 LINK
        uint96 gasPrice = 1e9; // 1 gwei
        int256 weiPerUnitLink = 1e18; // 1 LINK

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                baseFee,
                gasPrice,
                weiPerUnitLink
            );
        vm.stopBroadcast();

        return
            NetworkConfig({
                subId: vm.envUint("SUBSCRIPTION_ID"),
                vrfCoordinator: address(vrfCoordinatorV2_5Mock),
                gasLane: vm.envBytes32("KEY_HASH"),
                gasLimit: uint32(vm.envUint("CALLBACK_GAS_LIMIT")),
                requestConfirmations: uint16(
                    vm.envUint("REQUEST_CONFIRMATIONS")
                ),
                numWords: uint32(vm.envUint("NUMBER_OF_WORDS")),
                deployerKey: vm.envUint("DEFAULT_ANVIL_KEY")
            });
    }
}
