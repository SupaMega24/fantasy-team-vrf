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

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                subId: vm.envUint(""),
                vrfCoordinator: vm.envAddress(""),
                gasLane: vm.envBytes32(""),
                gasLimit: uint32(vm.envUint("")),
                requestConfirmations: uint16(vm.envUint("")),
                numWords: uint32(vm.envUint("")),
                deployerKey: vm.envUint("")
            });
    }

    function getOrCreateAnvilConfig()
        public
        view
        returns (NetworkConfig memory)
    {}
}
