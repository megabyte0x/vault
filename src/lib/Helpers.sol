// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";
import {TokenizedStrategyLogic} from "./TokenizedStrategyLogic.sol";
import {StrategyStateLogic} from "./StrategyStateLogic.sol";

/// @title Helpers
/// @notice Utility functions for validating strategy operations and state changes
/// @dev Centralized validation logic used across strategy management functions
/// @author megabyte0x.eth
library Helpers {
    using FixedPointMathLib for uint256;
    using TokenizedStrategyLogic for address;
    using StrategyStateLogic for DataTypes.StrategyState;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    /// @notice Validates parameters for fund reallocation operations
    /// @dev Checks if reallocation is feasible given current asset state
    /// @param s The strategy state storage reference
    /// @param totalAssets The total assets available for reallocation
    /// @param asset The underlying asset address
    function validateReallocateFunds(DataTypes.StrategyState storage s, uint256 totalAssets, address asset)
        internal
        view {
        //! TODO: Implement validation logic for fund reallocation
    }

    /// @notice Validates if a strategy can be safely removed from the vault
    /// @dev Checks strategy existence and withdrawal capabilities
    /// @param s The strategy state storage reference
    /// @param strategy The address of the strategy to remove
    function validateStrategyRemoval(DataTypes.StrategyState storage s, address strategy) internal view {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        if (s.strategyToIndex[strategy] == 0) revert Errors.StrategyNotFound();

        _validateMaxWithdraw(strategy);
    }

    /// @notice Validates if a new strategy can be added to the vault
    /// @dev Checks strategy limits, asset compatibility, and duplicate prevention
    /// @param s The strategy state storage reference
    /// @param strategy The address of the strategy to add
    /// @param asset The vault's underlying asset address
    /// @param maxStrategies The maximum number of strategies allowed
    function validateStrategyAddition(
        DataTypes.StrategyState storage s,
        address strategy,
        address asset,
        uint256 maxStrategies
    ) internal view {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        if (s.totalStrategies >= maxStrategies) revert Errors.MaxStrategiesReached();
        if (strategy.getAsset() != asset) revert Errors.WrongBaseAsset();
        if (s.strategyToIndex[strategy] != 0) revert Errors.StrategyAlreadyAdded();
    }

    /// @notice Validates if a strategy's allocation cap can be changed
    /// @dev Ensures the new cap is different from the current cap
    /// @param s The strategy state storage reference
    /// @param strategy The address of the strategy
    /// @param newCap The proposed new allocation cap
    function validateCapChange(DataTypes.StrategyState storage s, address strategy, uint256 newCap) internal view {
        uint256 index = s.getStrategyIndex(strategy);
        uint256 currentCap = s.strategies[index].cap;

        if (currentCap == newCap) revert Errors.NoChangeInCap();
    }

    /// @notice Validates a new supply queue configuration
    /// @dev Checks queue length and ensures all strategies have valid caps
    /// @param s The strategy state storage reference
    /// @param newSupplyQueue Array of strategy indices in desired supply order
    /// @param maxStrategies The maximum number of strategies allowed
    function validateNewSupplyQueue(
        DataTypes.StrategyState storage s,
        uint256[] memory newSupplyQueue,
        uint256 maxStrategies
    ) internal view {
        uint256 newLength = newSupplyQueue.length;

        if (newLength >= maxStrategies) revert Errors.MaxStrategiesReached();

        uint256 i = 0;
        for (i; i < newLength; i++) {
            if (s.strategies[newSupplyQueue[i]].cap == 0) revert Errors.ZeroCap();
        }
    }

    /// @notice Validates a new withdraw queue configuration
    /// @dev Ensures withdraw queue length doesn't exceed total strategies
    /// @param s The strategy state storage reference
    /// @param newWithdrawQueue Array of strategy indices in desired withdrawal order
    function validateNewWithdrawQueue(DataTypes.StrategyState storage s, uint256[] memory newWithdrawQueue)
        internal
        view
    {
        if (newWithdrawQueue.length > s.totalStrategies) revert Errors.WrongLength();
    }

    /// @notice Internal validation for strategy withdrawal capability
    /// @dev Checks if all funds can be withdrawn from a strategy (with 1 wei tolerance)
    /// @param strategy The address of the strategy to validate
    function _validateMaxWithdraw(address strategy) internal view {
        uint256 currentAssetBalance = strategy.getAssetBalanceInStrategy();
        uint256 maxWithdrawable = strategy.getMaxWithdrawable();

        // Allow 1 wei difference for rounding errors
        if (currentAssetBalance > maxWithdrawable + 1) {
            revert Errors.CannotWithdrawAllFundsFromStrategy();
        }
    }
}
