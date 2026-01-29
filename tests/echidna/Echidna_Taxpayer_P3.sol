// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

contract Echidna_Taxpayer_P3 {
    TaxpayerHarness[] internal people;

    constructor() {
        for (uint256 i = 0; i < 6; i++) {
            people.push(new TaxpayerHarness(address(uint160(100 + i)), address(uint160(200 + i))));
    
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

    function act_age(uint8 i, uint8 n) external {
        TaxpayerHarness a = _p(i);
        uint256 k = uint256(n) % 80;
        for (uint256 t = 0; t < k; t++) {
            a.haveBirthday();
    
        }
    
    }

    function echidna_p3_oap_min_7000() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            if (a.getAge() >= 65) {
                if (a.getTaxAllowance() < 7000) return false;
    
            }
    
        }
        return true;
    
    }
}