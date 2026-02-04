// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

/// @title Echidna Taxpayer P1 — Marriage Consistency Properties
/// @notice Echidna-based property tests for marriage symmetry and consistency
/// @dev This contract models a fixed population of TaxpayerHarness instances and
///      checks that marriage relationships are always globally consistent under
///      arbitrary sequences of marry and divorce operations.
contract Echidna_Taxpayer_P1 {
    /// @notice Fixed set of taxpayer instances used by Echidna
    /// @dev The population is intentionally bounded to allow exhaustive cross-checks
    ///      between all participants when validating global invariants.
    TaxpayerHarness[] internal people;

    /// @notice Deploys a fixed population of taxpayer harnesses
    /// @dev Each TaxpayerHarness is initialized with dummy parent addresses.
    ///      The bounded population size simplifies invariant checking.
    constructor() {
        // deploy 6 taxpayers with dummy parents (address(1), address(2), etc.)
        for (uint256 i = 0; i < 6; i++) {
            people.push(new TaxpayerHarness(address(uint160(100 + i)), address(uint160(200 + i))));
        }
    }

    /// @notice Returns a taxpayer instance selected by index
    /// @dev The index is reduced modulo the population size to avoid out-of-bounds access
    /// @param i Arbitrary index provided by Echidna
    /// @return A TaxpayerHarness instance from the population
    function _p(uint8 i) internal view returns (TaxpayerHarness) {
        return people[uint256(i) % people.length];
    }

    // actions
    /// @notice Attempts to marry two taxpayers
    /// @dev Action function used by Echidna to explore marriage-related state transitions
    /// @param i Index of the first taxpayer
    /// @param j Index of the second taxpayer
    function act_marry(uint8 i, uint8 j) external {
        TaxpayerHarness a = _p(i);
        TaxpayerHarness b = _p(j);
        a.marry(address(b));
    }

    /// @notice Attempts to divorce a taxpayer from their spouse
    /// @dev Action function used by Echidna to explore divorce-related state transitions
    /// @param i Index of the taxpayer
    function act_divorce(uint8 i) external {
        TaxpayerHarness a = _p(i);
        a.divorce();
    }

    /// @notice P1.1 — Marriage symmetry
    /// @dev If A is married to B and B is not the zero address, then B must be married to A
    /// @return True if the symmetry invariant holds for all taxpayers
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

    /// @notice P1.2 — No self-marriage
    /// @dev No taxpayer is allowed to be married to itself
    /// @return True if no self-marriage is detected
    function echidna_p1_no_self_marriage() external view returns (bool) {
        for (uint256 i = 0; i < people.length; i++) {
            TaxpayerHarness a = people[i];
            if (a.getSpouse() == address(a)) return false;
        }
        return true;
    }

    /// @notice P1.3 — Coherent unmarried state
    /// @dev If a taxpayer is unmarried, no other taxpayer may reference it as a spouse
    /// @return True if no dangling spouse references exist
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