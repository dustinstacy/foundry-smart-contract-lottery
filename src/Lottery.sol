// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

error Lottery__NotEnoughEthSent();

/**
 * @title A sample Lottery Contract
 * @author Dustin Stacy
 * @notice This contract is for creating a sample lottery
 * @dev Implents Chainlink VRFv2
 */
contract Lottery {
    uint256 private immutable i_entranceFee;
    address payable[] private s_entrants;

    event LotteryEntered(address indexed entrant);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterLottery() external payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        s_entrants.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function chooseWinner() public {}

    /** Getter Functions **/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
