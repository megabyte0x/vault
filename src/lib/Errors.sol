// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Errors
/// @notice Library containing custom error definitions for the vault system
/// @dev Centralized error definitions improve gas efficiency and maintainability
/// @author megabyte0x.eth
library Errors {
    /// @notice Thrown when a zero address is provided where a valid address is required
    error ZeroAddress();

    /// @notice Thrown when a zero amount is provided where a positive amount is required
    error ZeroAmount();

    /// @notice Thrown when attempting to add strategies beyond the maximum allowed
    error MaxStrategiesReached();

    /// @notice Thrown when the total cap across all strategies would be exceeded
    error TotalCapExceeded();

    /// @notice Thrown when attempting to add a strategy that already exists
    error StrategyAlreadyAdded();

    /// @notice Thrown when strategy's asset doesn't match vault's underlying asset
    error WrongBaseAsset();

    /// @notice Thrown when attempting operations on a strategy that doesn't exist
    error StrategyNotFound();

    /// @notice Thrown when attempting to withdraw all funds from a strategy is not allowed
    error CannotWithdrawAllFundsFromStrategy();

    /// @notice Thrown when attempting to set a cap to the same value it already has
    error NoChangeInCap();

    /// @notice Thrown when the minimum idle asset requirement is not met
    error MinimumIdleAssetNotReached();

    /// @notice Thrown when insufficient funds are available for the requested operation
    error NotEnoughFundsAvailable();

    /// @notice Thrown when all strategies have reached their allocation caps
    error AllCapsReached();

    /// @notice Thrown when there's insufficient liquidity for withdrawal operations
    error NotEnoughLiquidity();

    /// @notice Thrown when attempting to set a strategy cap to zero
    error ZeroCap();

    /// @notice Thrown when array lengths don't match expected values
    error WrongLength();

    /// @notice Thrown when a strategy appears multiple times in a queue
    /// @param strategyIndex The index of the duplicated strategy
    error DuplicateStrategy(uint256 strategyIndex);

    /// @notice Thrown when attempting to remove a strategy that still has asset balance
    /// @param strategyIndex The index of the strategy with non-zero balance
    error InvalidStrategyRemovalWithNonZeroAssetBalance(uint256 strategyIndex);

    /// @notice Thrown when attempting to remove a strategy that still has allocation cap
    /// @param strategyIndex The index of the strategy with non-zero cap
    error InvalidStrategyRemovalWithNonZeroCap(uint256 strategyIndex);

    /// @notice Thrown when a strategy in a queue has zero allocation cap
    /// @param strategyIndex The index of the strategy with zero cap
    error StrategyWithZeroCap(uint256 strategyIndex);

    /// @notice Thrown when attempting to supply more than a strategy's cap allows
    /// @param strategyIndex The index of the strategy that would exceed its cap
    error SupplyCapExceeded(uint256 strategyIndex);

    /// @notice Thrown when reallocation parameters are invalid or inconsistent
    error InvalidReallocation();
}
