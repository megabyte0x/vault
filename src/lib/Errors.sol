// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Errors
/// @notice Library containing custom error definitions for the vault system
/// @dev Centralized error definitions improve gas efficiency and maintainability
/// @author megabyte0x.eth
library Errors {
    /// @notice Thrown when a zero address is provided where a valid address is required
    error ZeroAddress();

    /// @notice Thrown when invalid input parameters are provided to a function
    error InvalidInputs();

    /// @notice Thrown when deposit amount is below the minimum required threshold
    error MinimumAssetRequired();

    error ZeroAmount();

    error MaxStrategiesReached();

    error TotalAllocationExceeded();
}
