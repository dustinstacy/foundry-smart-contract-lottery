// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLottery is Script {
    function run() public {}

    function deployContract()
        public
        returns (Lottery lottery, HelperConfig helperConfig)
    {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        lottery = new Lottery(
            config.vrfCoordinator,
            config.gasLane,
            config.entranceFee,
            config.interval,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (lottery, helperConfig);
    }
}
