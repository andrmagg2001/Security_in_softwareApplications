// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../../contracts/Lottery.sol";

/// @title LotteryHarness
/// @notice Echidna testing harness for the Lottery contract
/// @dev This contract exposes the Lottery logic unchanged and is used exclusively
///      for property-based fuzzing with Echidna. No additional state or behavior
///      is introduced beyond the inherited contract.
contract LotteryHarness is Lottery {
    /// @notice Deploys the Lottery harness with a fixed period
    /// @param p Duration (in seconds) of each lottery phase (commit and reveal)
    /// @dev The constructor simply forwards the parameter to the base Lottery contract.
    constructor(uint256 p) Lottery(p) {}
    
}