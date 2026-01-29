// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../../contracts/Taxpayer.sol";

contract TaxpayerHarness is Taxpayer {
    constructor(address p1, address p2) Taxpayer(p1, p2) {}

    function getSpouse() external view returns (address) {
        return spouse;
    
    }

    function getIsMarried() external view returns (bool) {
        return isMarried;
    
    }

    function getAge() external view returns (uint) {
        return age;

    }
}