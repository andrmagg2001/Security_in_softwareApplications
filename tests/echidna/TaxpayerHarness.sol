// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../../contracts/Taxpayer.sol";

/// @title TaxpayerHarness
/// @notice Echidna harness that exposes internal Taxpayer state via getters for invariant testing.
/// @dev This contract inherits Taxpayer and adds view-only helpers; it must not modify the core logic.
contract TaxpayerHarness is Taxpayer {
    /// @notice Deploys the harness by initializing the underlying Taxpayer contract.
    /// @param p1 First address used to initialize Taxpayer state.
    /// @param p2 Second address used to initialize Taxpayer state.
    constructor(address p1, address p2) Taxpayer(p1, p2) {}

    /// @notice Returns the current spouse address stored in the Taxpayer state.
    /// @return The spouse address (zero address if not married).
    function getSpouse() external view returns (address) {
        return spouse;
    }

    /// @notice Returns whether the taxpayer is currently marked as married.
    /// @return True if married, false otherwise.
    function getIsMarried() external view returns (bool) {
        return isMarried;
    }

    /// @notice Returns the current age stored in the Taxpayer state.
    /// @return The taxpayer age.
    function getAge() external view returns (uint) {
        return age;
    }
}