// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../../contracts/Lottery.sol";

contract LotteryHarness is Lottery {
    constructor(uint256 p) Lottery(p) {}
    
}