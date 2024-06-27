// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/v0.8/VRFConsumerBaseV2.sol";

error Lottery__NotEnoughEthSent();
error Lottery__NotEnoughTimeHasPassed();
error Lottery__TransferFailed();
error Lottery__LotteryNotOpen();

/**
 * @title A sample Lottery Contract
 * @author Dustin Stacy
 * @notice This contract is for creating a sample lottery
 * @dev Implents Chainlink VRFv2
 */
contract Lottery is VRFConsumerBaseV2 {
    /** Type declarations **/
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /** State Variables **/
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_entrants;
    address private s_recentWinner;
    uint256 private s_lastTimeStamp;
    LotteryState private s_lotteryState;

    event LotteryEntered(address indexed entrant);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 entranceFee,
        uint256 interval,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_lotteryState = LotteryState.OPEN;
    }

    function enterLottery() external payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }
        s_entrants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function chooseWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert Lottery__NotEnoughTimeHasPassed();
        }
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_entrants.length;
        address payable winner = s_entrants[indexOfWinner];

        s_recentWinner = winner;
        s_lotteryState = LotteryState.OPEN;
        s_entrants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(s_recentWinner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    /** Getter Functions **/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
