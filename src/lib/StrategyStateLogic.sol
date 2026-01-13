// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {TokenizedStrategyLogic} from "./TokenizedStrategyLogic.sol";

import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";

/// @title StrategyStateLogic
/// @notice Library for managing strategy state operations including addition, removal, and queue management
/// @dev Handles all strategy state transitions and maintains data consistency
/// @author megabyte0x.eth
library StrategyStateLogic {
    using TokenizedStrategyLogic for address;

    /// @notice Retrieves the index of a strategy in the strategies array
    /// @dev Reverts if strategy is not found. Returns actual index (subtracts 1 from stored value)
    /// @param s The strategy state storage reference
    /// @param strategy The address of the strategy to look up
    /// @return index The zero-based index of the strategy
    function getStrategyIndex(DataTypes.StrategyState storage s, address strategy)
        internal
        view
        returns (uint256 index)
    {
        uint256 ip1 = s.strategyToIndex[strategy];
        if (ip1 == 0) revert Errors.StrategyNotFound();
        index = ip1 - 1;
    }

    /// @notice Adds a new strategy to the vault with the specified allocation cap
    /// @dev Adds strategy to both supply and withdraw queues, increments total strategies count
    /// @param s The strategy state storage reference
    /// @param newStrategy The address of the strategy to add
    /// @param cap The maximum allocation cap for the strategy
    function addStrategy(DataTypes.StrategyState storage s, address newStrategy, uint256 cap) internal {
        s.strategies[s.totalStrategies] = DataTypes.Strategy({strategy: newStrategy, cap: cap});

        s.supplyQueue.push(s.totalStrategies);
        s.withdrawQueue.push(s.totalStrategies);

        // Store index + 1 to differentiate between unset (0) and first strategy (1)
        s.strategyToIndex[newStrategy] = ++s.totalStrategies;
    }

    /// @notice Updates the allocation cap for an existing strategy
    /// @dev Uses getStrategyIndex to locate the strategy and update its cap
    /// @param s The strategy state storage reference
    /// @param strategy The address of the strategy to modify
    /// @param newCap The new allocation cap for the strategy
    function changeCap(DataTypes.StrategyState storage s, address strategy, uint256 newCap) internal {
        s.strategies[getStrategyIndex(s, strategy)].cap = newCap;
    }

    /// @notice Updates the supply queue order for strategy allocation priority
    /// @dev Directly replaces the current supply queue with the new one
    /// @param s The strategy state storage reference
    /// @param newQueue Array of strategy indices in desired supply order
    function updateSupplyQueue(DataTypes.StrategyState storage s, uint256[] memory newQueue) internal {
        s.supplyQueue = newQueue;
    }

    /// @notice Updates the withdraw queue and removes strategies not included in the new queue
    /// @dev Validates that removed strategies have zero cap and balance before deletion
    /// @param s The strategy state storage reference
    /// @param newQueue Array of indices referencing positions in current withdraw queue
    function updateWithdrawQueue(DataTypes.StrategyState storage s, uint256[] memory newQueue) internal {
        uint256[] memory currentWithdrawQueue = s.withdrawQueue;
        uint256 newLength = newQueue.length;
        uint256 currLength = currentWithdrawQueue.length;

        // Track which strategies from current queue are included in new queue
        bool[] memory seen = new bool[](currLength);
        uint256[] memory newWithdrawQueue = new uint256[](newLength);

        // Build new queue and mark included strategies
        for (uint256 i; i < newLength; ++i) {
            uint256 prevIndex = newQueue[i];

            // Get strategy ID from current queue at the specified index
            uint256 id = currentWithdrawQueue[prevIndex];
            if (seen[prevIndex]) revert Errors.DuplicateStrategy(id);
            seen[prevIndex] = true;

            newWithdrawQueue[i] = id;
        }

        // Remove strategies not included in the new queue
        for (uint256 i; i < currLength; ++i) {
            if (!seen[i]) {
                uint256 id = currentWithdrawQueue[i];
                DataTypes.Strategy memory strategy = s.strategies[id];

                // Validate strategy can be safely removed
                if (strategy.cap != 0) revert Errors.InvalidStrategyRemovalWithNonZeroCap(id);

                if (strategy.strategy.getAssetBalanceInStrategy() != 0) {
                    revert Errors.InvalidStrategyRemovalWithNonZeroAssetBalance(id);
                }

                delete s.strategies[id];
            }
        }

        s.withdrawQueue = newWithdrawQueue;
    }
}
