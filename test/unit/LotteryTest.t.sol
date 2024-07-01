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
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public ENTRANT = makeAddr("entrant");
    uint256 public constant STARTING_ENTRANT_BALANCE = 10 ether;

    event LotteryEntered(address indexed entrant);
    event WinnerPicked(address indexed winner);

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

    /*//////////////////////////////////////////////////////////////
                             ENTER LOTTERY
    //////////////////////////////////////////////////////////////*/

    function testEnterLotteryRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(ENTRANT);
        // Act / Assert
        vm.expectRevert(Lottery.Lottery__NotEnoughEthSent.selector);
        lottery.enterLottery();
    }

    function testEnterLotteryRecordsEntrantsWhenTheyEnter() public {
        // Arrange
        vm.prank(ENTRANT);
        // Act
        lottery.enterLottery{value: entranceFee}();
        // Assert
        address entrantRecorded = lottery.getEntrant(0);
        assert(entrantRecorded == ENTRANT);
    }

    function testLotteryEnteredEventEmits() public {
        // Arrange
        vm.prank(ENTRANT);
        // Act / Assert
        vm.expectEmit(true, false, false, false, address(lottery));
        emit LotteryEntered(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
    }

    function testEnterLotteryRevertsWhenLotteryIsCalculating() public {
        // Arrange
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
        // Act / Assert
        vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFalseIfHasNoEntrants() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfLotteryCalculating() public {
        // Arrange
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        // Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        // Assert
        assert(lotteryState == Lottery.LotteryState.CALCULATING);
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        // Arrange
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
        // Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(ENTRANT);
        lottery.enterLottery{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act / Assert
        lottery.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        uint256 currentBalance = 0;
        uint256 numEntrants = 0;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery__UpkeepNotNeeded.selector,
                interval,
                lotteryState,
                currentBalance,
                numEntrants
            )
        );
        lottery.performUpkeep("");
    }
}
