// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

contract Echidna_Taxpayer_P2 {
    TaxpayerHarness[] internal people;

    constructor() {
        for (uint256 i = 0; i < 6; i++)
        {
            people.push(new TaxpayerHarness(address(uint160(100 + 1)), address(uint160(200 + i))));

        }
    }

    function _p(uint8 i) internal view returns (TaxpayerHarness) {
        return people[uint256(i) % people.length];
    }

    function act_marry(uint8 i, uint8 j) external {
        TaxpayerHarness a = _p(i);
        TaxpayerHarness b = _p(j);
        a.marry(address(b));
    }

    function act_divorce(uint8 i) external {
        TaxpayerHarness a = _p(i);
        a.divorce();
    }

    function act_transfer(uint8 i, uint16 amount) external {
        TaxpayerHarness a = _p(i);

        uint256 change = uint256(amount) % 5000; 
        if (change == 0) return;

        if (a.getTaxAllowance() < change) return;

        a.transferAllowance(change);
    }

    function echidna_p2_unmarried_baseline_5000() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            if (a.getSpouse() == address(0)) {
                if (a.getTaxAllowance() != 5000) return false;
            }
        }
        return true;
    }

    function echidna_p2_pooling_conservation_sum_10000() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            address bAddr = a.getSpouse();
            if (bAddr != address(0)) {
                TaxpayerHarness b = TaxpayerHarness(bAddr);

                if (b.getSpouse() == address(a)) {
                    uint256 sum = a.getTaxAllowance() + b.getTaxAllowance();
                    if (sum != 10000) return false;

                }
            }
        }
        return true;
    }
}