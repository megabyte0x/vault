// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";
import {TokenizedStrategyLogic} from "./TokenizedStrategyLogic.sol";

library Helpers {
    using FixedPointMathLib for uint256;
    using TokenizedStrategyLogic for address;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    uint256 internal constant MAX_STRATEGIES = 10;

    function currentTotalAllocation(DataTypes.StrategyState storage s) internal view returns (uint256 totalAllocation) {
        uint256 i = 0;

        for (i; i < s.totalStrategies; i++) {
            totalAllocation = totalAllocation.rawAdd(s.strategies[i].allocation);
        }
    }

    function validateReallocateFunds(DataTypes.StrategyState storage s, uint256 totalAssets, address asset)
        internal
        view
    {
        uint256 currentBalance = ERC20(asset).balanceOf(address(this));

        if (totalAssets.mulDiv(s.minimumIdleAssets, BASIS_POINT_SCALE) > currentBalance) {
            revert Errors.MinimumIdleAssetNotReached();
        }
    }

    function validateStrategyRemoval(DataTypes.StrategyState storage s, address strategy) internal view {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        if (s.strategyToIndex[strategy] == 0) revert Errors.StrategyNotFound();

        _validateMaxWithdraw(strategy);
    }

    function validateStrategyAddition(
        DataTypes.StrategyState storage s,
        address strategy,
        uint256 allocation,
        address asset
    ) internal view {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        if (s.totalStrategies >= MAX_STRATEGIES) revert Errors.MaxStrategiesReached();
        if (strategy.getAsset() != asset) revert Errors.WrongBaseAsset();

        if (s.strategyToIndex[strategy] != 0) revert Errors.StrategyAlreadyAdded();

        _validateTotalAllocation(s, allocation);
    }

    function validateAllocationChange(DataTypes.StrategyState storage s, address strategy, uint256 newAllocation)
        internal
        view
    {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        uint256 index = s.strategyToIndex[strategy];
        if (index == 0) revert Errors.StrategyNotFound();

        uint256 currentAllocation = s.strategies[index - 1].allocation;

        if (currentAllocation == newAllocation) revert Errors.NoChangeInAllocation();

        if (currentTotalAllocation(s) - currentAllocation + newAllocation > BASIS_POINT_SCALE) {
            revert Errors.TotalAllocationExceeded();
        }
    }

    function _validateTotalAllocation(DataTypes.StrategyState storage s, uint256 allocation) internal view {
        if (allocation == 0) revert Errors.ZeroAmount();

        if (currentTotalAllocation(s) > BASIS_POINT_SCALE - allocation) {
            revert Errors.TotalAllocationExceeded();
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
