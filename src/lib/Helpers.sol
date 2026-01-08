// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";
import {TokenizedStrategyLogic} from "./TokenizedStrategyLogic.sol";
import {StrategyStateLogic} from "./StrategyStateLogic.sol";

library Helpers {
    using FixedPointMathLib for uint256;
    using TokenizedStrategyLogic for address;
    using StrategyStateLogic for DataTypes.StrategyState;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    function validateReallocateFunds(DataTypes.StrategyState storage s, uint256 totalAssets, address asset)
        internal
        view {
        //! TODO
    }

    function validateStrategyRemoval(DataTypes.StrategyState storage s, address strategy) internal view {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        if (s.strategyToIndex[strategy] == 0) revert Errors.StrategyNotFound();

        _validateMaxWithdraw(strategy);
    }

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

    function validateCapChange(DataTypes.StrategyState storage s, address strategy, uint256 newCap) internal view {
        uint256 index = s.getStrategyIndex(strategy);
        uint256 currentCap = s.strategies[index].cap;

        if (currentCap == newCap) revert Errors.NoChangeInCap();

        if (currentCap != 0) {
            // !Todo: Check for pending cap change
        }
    }

    function _validateMaxWithdraw(address strategy) internal view {
        uint256 currentAssetBalance = strategy.getAssetBalanceInStrategy();
        uint256 maxWithdrawable = strategy.getMaxWithdrawable();

        if (currentAssetBalance > maxWithdrawable + 1) {
            revert Errors.CannotWithdrawAllFundsFromStrategy();
        }
    }
}
