// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";

/**
 * @title State Logic
 * @author @megabyte0x.eth
 * @notice This library is used to update the internal `s_strategy` variable of the contract.
 */
library StrategyStateLogic {
    /**
     * @notice Returns the `index` of `strategy`.
     * @param s Current `State`
     * @param strategy Strategy address to find `index` for
     */
    function getStrategyIndex(DataTypes.StrategyState storage s, address strategy)
        internal
        view
        returns (uint256 index)
    {
        uint256 ip1 = s.strategyToIndex[strategy];
        if (ip1 == 0) revert Errors.StrategyNotFound();
        index = ip1 - 1;
    }

    /**
     * @notice This adds the strategy in the `strategies` mapping, increase the `totalStrategies` by 1 and adds the updated `totalStrategy` as index in `strategyToIndex` for `newStrategy`.
     * @param s Current `State`
     * @param newStrategy New strategy address
     * @param cap New strategy cap
     */
    function addStrategy(DataTypes.StrategyState storage s, address newStrategy, uint256 cap) internal {
        s.strategies[s.totalStrategies] = DataTypes.Strategy({strategy: newStrategy, cap: cap});
        /// @dev Index + 1, this will prevent any addition to 0 index.
        s.strategyToIndex[newStrategy] = ++s.totalStrategies;
        //! TODO: Manage supply queue
    }

    /**
     * This removes the `strategy` from the `strategies` mapping, decrease the `totalStrategies` by 1 and updates the `strategyToIndex` to 0.
     * @param s Current `State`
     * @param strategy Strategy address to remove
     */
    function removeStrategy(DataTypes.StrategyState storage s, address strategy) internal {
        uint256 idx = getStrategyIndex(s, strategy);
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
     * This changes the cap of `strategy` and updates the `strategies` mapping with the `newCap`.
     * @param s Current `State`
     * @param strategy Strategy address whose cap needs to change.
     * @param newCap The new cap for the `strategy`.
     */
    function changeCap(DataTypes.StrategyState storage s, address strategy, uint256 newCap) internal {
        s.strategies[getStrategyIndex(s, strategy)].cap = newCap;
    }
}
