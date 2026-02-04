// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Echidna Dummy Harness
/// @author Andrea Maggiore
/// @notice Minimal contract used to validate the Echidna setup and workflow.
/// @dev Exposes simple state transitions (inc/dec) and a trivial invariant.
contract EchidnaDummy {
    /// @notice Example state variable fuzzed by Echidna.
    uint256 public x;

    /// @notice Increments x by 1.
    /// @dev This is an action function that Echidna can call to mutate state.
    function inc() external {
        x += 1;
    }

    /// @notice Decrements x by 1.
    /// @dev With Solidity >=0.8.0, underflow reverts automatically.
    function dec() external {
        x -= 1;
    }

    /// @notice Property: x is always non-negative.
    /// @dev Trivial invariant because x is uint256; kept as a smoke-test property.
    /// @return True in all reachable states.
    function echidna_x_non_negative() external view returns (bool) {
        return x >= 0;
    }
}