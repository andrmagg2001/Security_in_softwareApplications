// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../../contracts/Lottery.sol";

contract LotteryHarness is Lottery {
    constructor(uint256 p) Lottery(p) {}

    function getCommit(address a) external view returns (bytes32) {
        return commits[a];
    }

    function getReveal(address a) external view returns (uint256) {
        return reveals[a];
    }

    function getRevealedLen() external view returns (uint256) {
        return revealed.length;
    }

    function getRevealedAt(uint256 i) external view returns (address) {
        if (i >= revealed.length) return address(0);
        return revealed[i];
    }

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function getRevealTime() external view returns (uint256) {
        return revealTime;
    }

    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    function getPeriod() external view returns (uint256) {
        return period;
    }
}