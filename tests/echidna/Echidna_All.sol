// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./TaxpayerHarness.sol";

/// @title Echidna All-In-One Property Harness
/// @notice Property-based fuzzing harness for the Taxpayer contract
/// @dev Encodes global invariants over marriage, allowance pooling, and age-based rules
contract Echidna_All {

    /// @dev Two independent taxpayer instances used to explore interaction invariants
    TaxpayerHarness internal A;
    TaxpayerHarness internal B;

    /// @notice Initializes two isolated TaxpayerHarness instances
    /// @dev Both start unmarried with baseline allowance
    constructor() {
        A = new TaxpayerHarness(address(0), address(0));
        B = new TaxpayerHarness(address(0), address(0));
    }

    /// @dev Computes the baseline allowance based on taxpayer age
    /// @param age Age of the taxpayer
    /// @return Baseline allowance (5000 or 7000 if age >= 65)
    function _baseline(uint256 age) internal pure returns (uint256) {
        return (age >= 65) ? 7000 : 5000;
    }

    /// @dev Selects a taxpayer instance based on a fuzzed selector
    /// @param who Selector value
    /// @return Selected TaxpayerHarness instance
    function _pick(uint8 who) internal view returns (TaxpayerHarness) {
        return (who % 2 == 0) ? A : B;
    }

    /// @dev Returns the counterpart of the given taxpayer
    /// @param t Reference taxpayer
    /// @return The other TaxpayerHarness instance
    function _other(TaxpayerHarness t) internal view returns (TaxpayerHarness) {
        return (address(t) == address(A)) ? B : A;
    }

    /// @dev Checks whether both taxpayers are married to each other
    /// @return True if marriage is reciprocal and consistent
    function _marriedReciprocal() internal view returns (bool) {
        return (A.getSpouse() == address(B)) &&
               (B.getSpouse() == address(A)) &&
               A.getIsMarried() &&
               B.getIsMarried();
    }

    /// @notice Attempts to marry two taxpayers
    /// @dev Guarded to avoid invalid transitions; Echidna explores valid paths only
    /// @param who Selector for initiating taxpayer
    function act_marry(uint8 who) public {
        TaxpayerHarness x = _pick(who);
        TaxpayerHarness y = _other(x);

        if (x.getIsMarried() || y.getIsMarried()) return;
        if (x.getSpouse() != address(0) || y.getSpouse() != address(0)) return;

        x.marry(address(y));
    }

    /// @notice Attempts to divorce a taxpayer
    /// @dev No-op if taxpayer is not married
    /// @param who Selector for taxpayer
    function act_divorce(uint8 who) public {
        TaxpayerHarness x = _pick(who);
        if (!x.getIsMarried()) return;
        x.divorce();
    }

    /// @notice Attempts an allowance transfer between married taxpayers
    /// @dev Respects baseline constraints and pooling invariants
    /// @param who Selector for sender
    /// @param raw Raw fuzzed input used to derive transfer amount
    function act_transfer(uint8 who, uint256 raw) public {
        TaxpayerHarness x = _pick(who);
        TaxpayerHarness y = _other(x);

        if (!_marriedReciprocal()) return;
        if (x.getSpouse() != address(y)) return;

        uint256 allowance = x.getTaxAllowance();
        uint256 floor = _baseline(x.getAge());

        if (allowance <= floor) return;

        uint256 maxSend = allowance - floor;
        uint256 amount = (raw % maxSend) + 1;

        x.transferAllowance(amount);
    }

    /// @notice Advances the age of a taxpayer by a bounded number of years
    /// @dev Used to explore age-based allowance thresholds
    /// @param who Selector for taxpayer
    /// @param times Raw fuzz input controlling number of birthdays
    function act_age(uint8 who, uint256 times) public {
        TaxpayerHarness x = _pick(who);
        uint256 t = times % 5;
        for (uint256 k = 0; k < t; k++) {
            x.haveBirthday();
        }
    }

    /// @notice Property: a taxpayer must never be married to itself
    /// @return True if self-marriage never occurs
    function echidna_all_no_self_marriage() public view returns (bool) {
        return (A.getSpouse() != address(A)) &&
               (B.getSpouse() != address(B));
    }

    /// @notice Property: marriage must be symmetric
    /// @dev Prevents asymmetric or dangling spouse references
    /// @return True if marriage relationship is globally consistent
    function echidna_all_symmetry() public view returns (bool) {
        if (A.getSpouse() != address(0) && A.getSpouse() != address(B)) return false;
        if (B.getSpouse() != address(0) && B.getSpouse() != address(A)) return false;

        if (A.getSpouse() == address(B) && B.getSpouse() != address(A)) return false;
        if (B.getSpouse() == address(A) && A.getSpouse() != address(B)) return false;

        return true;
    }

    /// @notice Property: unmarried taxpayers must have baseline allowance
    /// @return True if baseline allowance invariant holds
    function echidna_all_unmarried_baseline() public view returns (bool) {
        if (A.getSpouse() == address(0)) {
            if (A.getTaxAllowance() != _baseline(A.getAge())) return false;
        }
        if (B.getSpouse() == address(0)) {
            if (B.getTaxAllowance() != _baseline(B.getAge())) return false;
        }
        return true;
    }

    /// @notice Property: elderly taxpayers must receive at least 7000 allowance
    /// @return True if age-based minimum allowance is respected
    function echidna_all_oap_min_7000() public view returns (bool) {
        if (A.getAge() >= 65 && A.getTaxAllowance() < 7000) return false;
        if (B.getAge() >= 65 && B.getTaxAllowance() < 7000) return false;
        return true;
    }

    /// @notice Property: pooled allowance must equal baseline sum
    /// @dev Prevents allowance creation or loss during marriage
    /// @return True if allowance pooling is conservative
    function echidna_all_pooling_sum_equals_baseline_sum() public view returns (bool) {
        if (!_marriedReciprocal()) return true;

        uint256 sum = A.getTaxAllowance() + B.getTaxAllowance();
        uint256 baseSum = _baseline(A.getAge()) + _baseline(B.getAge());
        return sum == baseSum;
    }
}