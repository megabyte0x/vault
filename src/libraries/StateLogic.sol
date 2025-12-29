// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {DataTypes} from "./DataTypes.sol";

library StateLogic {
    function addStrategy(DataTypes.State storage s, address newStrategy, uint256 allocation) internal {
        s.strategies[s.totalStrategies] = DataTypes.Strategy({strategy: newStrategy, allocation: allocation});
        /// @dev Index + 1, this will prevent any addition to 0 index.
        s.strategyToIndex[newStrategy] = ++s.totalStrategies;
    }

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
}
