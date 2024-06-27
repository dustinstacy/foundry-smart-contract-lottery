// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 entranceFee;
        uint256 interval;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaConfig)
    {
        sepoliaConfig = NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            entranceFee: .01 ether,
            interval: 60,
            subscriptionId: 4673,
            callbackGasLimit: 500000
        });
    }

    function getAnvilConfig()
        public
        view
        returns (NetworkConfig memory anvilConfig)
    {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        anvilConfig = NetworkConfig({
            vrfCoordinator: address(0),
            gasLane: "",
            entranceFee: 1 ether,
            interval: 30,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }
}
