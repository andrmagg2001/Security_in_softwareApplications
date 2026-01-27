// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

contract Echidna_Taxpayer_P1 {
    TaxpayerHarness[] internal people;

    constructor() {
        // deploy 6 taxpayers with dummy parents (address(1), address(2), etc.)
        for (uint256 i = 0; i < 6; i++) {
            people.push(new TaxpayerHarness(address(uint160(100 + i)), address(uint160(200 + i))));
        }
    }

    function _p(uint8 i) internal view returns (TaxpayerHarness) {
        return people[uint256(i) % people.length];
    }

    // actions
    function act_marry(uint8 i, uint8 j) external {
        TaxpayerHarness a = _p(i);
        TaxpayerHarness b = _p(j);
        a.marry(address(b));
    }

    function act_divorce(uint8 i) external {
        TaxpayerHarness a = _p(i);
        a.divorce();
    }

    // P1.1 Symmetry: if A.spouse == B != 0 then B.spouse == A
    function echidna_p1_symmetry() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            address bAddr = a.getSpouse();
            if (bAddr != address(0)) {
                TaxpayerHarness b = TaxpayerHarness(bAddr);
                if (b.getSpouse() != address(a)) return false;
            }
        }
        return true;
    }

    // P1.2 No self-marriage
    function echidna_p1_no_self_marriage() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            if (a.getSpouse() == address(a)) return false;
        }
        return true;
    }

    // P1.3 Coherent unmarried: if A.spouse == 0 then no one points to A
    function echidna_p1_coherent_unmarried() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            if (a.getSpouse() == address(0)) {
                for (uint256 j = 0; j < people.length; j++) {
                    TaxpayerHarness x = people[j];
                    if (x.getSpouse() == address(a)) return false;
                }
            }
        }
        return true;
    }
}