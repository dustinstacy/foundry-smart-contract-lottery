// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/v0.8/VRFConsumerBaseV2.sol";

error Lottery__NotEnoughEthSent();
error Lottery__NotEnoughTimeHasPassed();

/**
 * @title A sample Lottery Contract
 * @author Dustin Stacy
 * @notice This contract is for creating a sample lottery
 * @dev Implents Chainlink VRFv2
 */
contract Lottery is VRFConsumerBaseV2 {
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
    uint256 private s_lastTimeStamp;

    event LotteryEntered(address indexed entrant);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_lastTimeStamp = block.timestamp;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterLottery() external payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        s_entrants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function chooseWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert Lottery__NotEnoughTimeHasPassed();
        }
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
    ) internal override {}

    /** Getter Functions **/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
