// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DataTypes} from "./DataTypes.sol";

/**
 * @title State Logic
 * @author @megabyte0x.eth
 * @notice This library is used to update the internal `s_state` variable of the contract.
 */
library StateLogic {
    /**
     * @notice This adds the strategy in the `strategies` mapping, increase the `totalStrategies` by 1 and adds the updated `totalStrategy` as index in `strategyToIndex` for `newStrategy`.
     * @param s Current `State`
     * @param newStrategy New strategy address
     * @param allocation New strategy allocation
     */
    function addStrategy(DataTypes.State storage s, address newStrategy, uint256 allocation) internal {
        s.strategies[s.totalStrategies] = DataTypes.Strategy({strategy: newStrategy, allocation: allocation});
        /// @dev Index + 1, this will prevent any addition to 0 index.
        s.strategyToIndex[newStrategy] = ++s.totalStrategies;
    }

    /**
     * This removes the `strategy` from the `strategies` mapping, decrease the `totalStrategies` by 1 and updates the `strategyToIndex` to 0.
     * @param s Current `State`
     * @param strategy Strategy address to remove
     */
    function removeStrategy(DataTypes.State storage s, address strategy) internal {
        uint256 idx = s.strategyToIndex[strategy] - 1;
        uint256 lastIdx = --s.totalStrategies;

        /// @dev if the strategy is not at the last index in the mapping, replace the last strtegy with the removing `strategy`.
        if (idx != lastIdx) {
            DataTypes.Strategy memory moved = s.strategies[lastIdx];
            s.strategies[idx] = moved;
            s.strategyToIndex[moved.strategy] = idx + 1;
        }
        /// @dev Delete the last strategy.
        delete s.strategies[lastIdx];
        delete s.strategyToIndex[strategy];
    }

    /**
     * This changes the allocation of `strategy` and updates the `strategies` mapping with the `newAllocation`.
     * @param s Current `State`
     * @param strategy Strategy address whose allocation needs to change.
     * @param newAllocation The new allocation for the `strategy`.
     */
    function changeAllocation(DataTypes.State storage s, address strategy, uint256 newAllocation) internal {
        s.strategies[s.strategyToIndex[strategy] - 1].allocation = newAllocation;
    }
}
