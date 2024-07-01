// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployLottery} from "../../script/DeployLottery.sol";
import {Lottery} from "src/Lottery.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    HelperConfig public helperConfig;

    address vrfCoordinator;
    bytes32 gasLane;
    uint256 entranceFee;
    uint256 interval;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public ENTRANT = makeAddr("entrant");
    uint256 public constant STARTING_ENTRANT_BALANCE = 10 ether;

    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        entranceFee = config.entranceFee;
        interval = config.interval;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(ENTRANT, STARTING_ENTRANT_BALANCE);
    }

    function testLotteryInitializesInOpenState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function testLotteryRevertsWhenYouDontPayEnough() public {
        //Arrange
        vm.prank(ENTRANT);
        //Act / Assert
        vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector);
        lottery.enterLottery();
    }

    function testLotteryRecordsEntrantsWhenTheyEnter() public {
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
        address entrantRecorded = lottery.getEntrant(0);
        assert(entrantRecorded == ENTRANT);
    }
}
