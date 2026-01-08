// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Errors
/// @notice Library containing custom error definitions for the vault system
/// @dev Centralized error definitions improve gas efficiency and maintainability
/// @author megabyte0x.eth
library Errors {
    /// @notice Thrown when a zero address is provided where a valid address is required
    error ZeroAddress();

    error ZeroAmount();

    error MaxStrategiesReached();

    error TotalCapExceeded();

    error StrategyAlreadyAdded();

    error WrongBaseAsset();

    error StrategyNotFound();

    error CannotWithdrawAllFundsFromStrategy();

    error NoChangeInCap();

    error MinimumIdleAssetNotReached();

    error NotEnoughFundsAvailable();

    error AllCapsReached();

    error NotEnoughLiquidity();
}
