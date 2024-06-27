// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery lottery) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            bytes32 gasLane,
            uint256 entranceFee,
            uint256 interval,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        lottery = new Lottery(
            vrfCoordinator,
            gasLane,
            entranceFee,
            interval,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        return lottery;
    }
}
