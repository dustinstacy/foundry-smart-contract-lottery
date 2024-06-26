// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title A sample Lottery Contract
 * @author Dustin Stacy
 * @notice This contract is for creating a sample lottery
 * @dev Implents Chainlink VRFv2
 */

contract Lottery {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterLottery() public payable {}

    function chooseWinner() public {}

    /** Getter Functions **/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
