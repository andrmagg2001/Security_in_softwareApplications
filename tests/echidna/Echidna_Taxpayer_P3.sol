// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

/// @title Echidna properties for Taxpayer — Elderly Allowance (P3)
/// @notice Echidna test contract validating minimum tax allowance guarantees for elderly taxpayers.
/// @dev This contract encodes property P3: taxpayers aged 65 or above must always have a minimum allowance of 7000.
contract Echidna_Taxpayer_P3 {
    /// @dev Fixed-size population of TaxpayerHarness instances used by Echidna to simulate multiple actors.
    TaxpayerHarness[] internal people;

    /// @notice Initializes a bounded population of taxpayers with deterministic addresses.
    /// @dev A small fixed population is sufficient to explore complex interaction patterns under fuzzing.
    constructor() {
        for (uint256 i = 0; i < 6; i++) {
            people.push(new TaxpayerHarness(address(uint160(100 + i)), address(uint160(200 + i))));
    
        }
    
    }

    /// @dev Deterministically selects a taxpayer from the population based on a fuzzed index.
    /// @param i Fuzzed index provided by Echidna.
    /// @return A TaxpayerHarness instance from the population.
    function _p(uint8 i) internal view returns (TaxpayerHarness) {
        return people[uint256(i) % people.length];
    
    }


    /// @notice Attempts to marry two taxpayers.
    /// @dev Action used by Echidna to explore marriage-related state transitions.
    function act_marry(uint8 i, uint8 j) external {
        TaxpayerHarness a = _p(i);
        TaxpayerHarness b = _p(j);
        a.marry(address(b));

    }

    /// @notice Attempts to divorce a taxpayer from their current spouse.
    /// @dev Used to explore post-divorce allowance and age-related behaviors.
    function act_divorce(uint8 i) external {
        TaxpayerHarness a = _p(i);
        a.divorce();

    }

    /// @notice Attempts to transfer part of the tax allowance.
    /// @dev The transferred amount is bounded to avoid trivial reverts and improve state-space exploration.
    function act_transfer(uint8 i, uint16 amount) external {
        TaxpayerHarness a = _p(i);

        uint256 change = uint256(amount) % 5000;
        if (change == 0) return;

        if (a.getTaxAllowance() < change) return;
        a.transferAllowance(change);
    
    }

    /// @notice Increments the age of a taxpayer by repeatedly invoking birthdays.
    /// @dev Used to explore age-dependent rules, especially transitions into elderly status.
    function act_age(uint8 i, uint8 n) external {
        TaxpayerHarness a = _p(i);
        uint256 k = uint256(n) % 80;
        for (uint256 t = 0; t < k; t++) {
            a.haveBirthday();
    
        }
    
    }

    /// @notice Property P3 — Elderly taxpayers must have a minimum allowance of 7000.
    /// @dev This invariant must hold for all taxpayers aged 65 or above, regardless of interaction history.
    /// @return True if the property holds for the entire population.
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