// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title A sample Lottery Contract
 * @author Dustin Stacy
 * @notice This contract is for creating a sample lottery
 * @dev Implents Chainlink VRFv2
 */
contract Lottery is VRFConsumerBaseV2Plus {
    /** Errors **/
    error Lottery__NotEnoughEthSent();
    error Lottery__UpkeepNotNeeded(
        uint256 timeToNextDrawing,
        uint256 state,
        uint256 balance,
        uint256 numEntrants
    );
    error Lottery__TransferFailed();
    error Lottery__LotteryNotOpen();

    /** Type declarations **/
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /** State Variables **/
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    bytes32 private immutable i_keyHash;
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
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_keyHash = gasLane;
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

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool enoughTimeHasPassed = (block.timestamp - s_lastTimeStamp) >=
            i_interval;
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool hasBalance = address(this).balance > 0;
        bool hasEnoughEntrants = s_entrants.length > 0;
        upkeepNeeded =
            enoughTimeHasPassed &&
            isOpen &&
            hasBalance &&
            hasEnoughEntrants;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                i_interval - (block.timestamp - s_lastTimeStamp),
                uint256(s_lotteryState),
                address(this).balance,
                s_entrants.length
            );
        }
        s_lotteryState = LotteryState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
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

    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    function getEntrant(
        uint256 indexOfEntrant
    ) external view returns (address) {
        return s_entrants[indexOfEntrant];
    }
}
