// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Events
/// @notice Centralized event definitions for the SimpleVTS vault system
/// @dev All events are prefixed with SimpleVTS__ to avoid naming conflicts
/// @author megabyte0x.eth
library Events {
    /// @notice Emitted when the entry fee is updated
    /// @param newEntryFee The new entry fee in basis points
    event SimpleVTS__EntryFeeUpdated(uint256 indexed newEntryFee);

    /// @notice Emitted when the exit fee is updated
    /// @param newExitFee The new exit fee in basis points
    event SimpleVTS__ExitFeeUpdated(uint256 indexed newExitFee);

    /// @notice Emitted when the fee recipient address is updated
    /// @param newFeeRecipient The new address that will receive fees
    event SimpleVTS__FeeRecipientUpdated(address indexed newFeeRecipient);

    /// @notice Emitted when the strategy contract is updated
    /// @param newStrategy The new strategy contract address
    event SimpleVTS__StrategyUpdated(address indexed newStrategy);

    /// @notice Emitted when a new tokenized strategy is added to the vault
    /// @param strategy The address of the added strategy
    /// @param cap The allocation cap set for the strategy
    event SimpleVTS__TokenizedStrategyAdded(address indexed strategy, uint256 indexed cap);

    /// @notice Emitted when a tokenized strategy is removed from the vault
    /// @param strategy The address of the removed strategy
    event SimpleVTS__TokenizedStrategyRemoved(address indexed strategy);

    /// @notice Emitted when a strategy's allocation cap is updated
    /// @param strategy The address of the strategy
    /// @param newCap The new allocation cap
    event SimpleVTS__CapUpdated(address indexed strategy, uint256 indexed newCap);

    /// @notice Emitted when funds are reallocated across strategies
    event SimpleVTS__FundsReallocated();

    /// @notice Emitted when the minimum idle assets threshold is updated
    /// @param newMinimumIdleAssets The new minimum idle assets amount
    event SimpleVTS__MinimumIdleAssetsUpdated(uint256 indexed newMinimumIdleAssets);

    /// @notice Emitted when emergency withdrawal of all funds is executed
    event SimpleVTS__EmergencyWithdrawFunds();

    /// @notice Emitted when the supply queue order is updated
    /// @param newSupplyQueue The new supply queue array with strategy indices
    event SimpleVTS__SupplyQueueUpdated(uint256[] indexed newSupplyQueue);

    /// @notice Emitted when the withdraw queue order is updated
    /// @param newWithdrawQueue The new withdraw queue array with strategy indices
    event SimpleVTS__WithdrawQueueUpdated(uint256[] indexed newWithdrawQueue);

    /// @notice Emitted when funds are withdrawn from a specific strategy
    /// @param strategyIndex The index of the strategy funds were withdrawn from
    /// @param amountWithdrawn The amount of assets withdrawn
    event SimpleVTS__WithdrewFromStrategy(uint256 strategyIndex, uint256 amountWithdrawn);

    /// @notice Emitted when funds are deposited into a specific strategy
    /// @param strategyIndex The index of the strategy funds were deposited into
    /// @param amountDeposited The amount of assets deposited
    event SimpleVTS__DepositedInStrategy(uint256 strategyIndex, uint256 amountDeposited);

    event SimpleVTS__MaxStrategiesUpdated(uint256 newMaxStrategies);
}
