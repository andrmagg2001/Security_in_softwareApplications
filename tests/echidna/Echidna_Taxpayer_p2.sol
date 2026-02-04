// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

/// @title Echidna Property-Based Test Harness for Taxpayer Contract
/// @notice This contract performs Echidna fuzzing tests to verify allowance baseline and pooling invariants
///         of the Taxpayer contract, ensuring correctness of marital status and allowance management.
contract Echidna_Taxpayer_P2 {
    /// @notice Represents a bounded population of taxpayers used for fuzzing
    TaxpayerHarness[] internal people;

    /// @notice Initializes a fixed-size population of TaxpayerHarness instances with deterministic addresses for reproducible fuzzing
    constructor() {
        for (uint256 i = 0; i < 6; i++)
        {
            people.push(new TaxpayerHarness(address(uint160(100 + 1)), address(uint160(200 + i))));

        }
    }

    /// @notice Deterministically maps an index to a taxpayer instance using modulo to ensure valid indexing
    /// @param i The index to map
    /// @return The TaxpayerHarness instance corresponding to the given index
    function _p(uint8 i) internal view returns (TaxpayerHarness) {
        return people[uint256(i) % people.length];
    }

    /// @notice Fuzzing action callable by Echidna to simulate marriage between two taxpayers
    /// @dev Inputs are sanitized using modulo to ensure valid indices
    /// @param i Index of the first taxpayer
    /// @param j Index of the second taxpayer
    function act_marry(uint8 i, uint8 j) external {
        TaxpayerHarness a = _p(i);
        TaxpayerHarness b = _p(j);
        a.marry(address(b));
    }

    /// @notice Fuzzing action callable by Echidna to simulate divorce of a taxpayer
    /// @dev Input is sanitized using modulo to ensure valid index
    /// @param i Index of the taxpayer
    function act_divorce(uint8 i) external {
        TaxpayerHarness a = _p(i);
        a.divorce();
    }

    /// @notice Fuzzing action callable by Echidna to simulate transfer of allowance by a taxpayer
    /// @dev Amount is sanitized using modulo and early returns to avoid zero or excessive transfers
    /// @param i Index of the taxpayer
    /// @param amount Amount proposed for transfer
    function act_transfer(uint8 i, uint16 amount) external {
        TaxpayerHarness a = _p(i);

        uint256 change = uint256(amount) % 5000; 
        if (change == 0) return;

        if (a.getTaxAllowance() < change) return;

        a.transferAllowance(change);
    }

    /// @notice Invariant check: Unmarried taxpayers must have a baseline allowance of 5000
    /// @return True if the invariant holds for all taxpayers, false otherwise
    function echidna_p2_unmarried_baseline_5000() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            if (a.getSpouse() == address(0)) {
                if (a.getTaxAllowance() != 5000) return false;
            }
        }
        return true;
    }

    /// @notice Invariant check: Mutually married couples must conserve a total allowance sum equal to 10000
    /// @return True if the invariant holds for all mutually married couples, false otherwise
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