// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {DataTypes} from "./DataTypes.sol";
import {Helpers} from "./Helpers.sol";
import {Errors} from "./Errors.sol";

import {SimpleTokenizedStrategy} from "../TokenizedStrategy/SimpleTokenizedStrategy.sol";

library TokenizedStrategyLogic {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;
    using Helpers for DataTypes.StrategyState;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    function getAsset(address strategy) internal view returns (address asset) {
        asset = SimpleTokenizedStrategy(strategy).asset();
    }

    function getAssetBalanceInStrategy(address strategy) internal view returns (uint256 assets) {
        /// @dev 1. Get the number of strategy shares.
        uint256 strategySharesBalance = SimpleTokenizedStrategy(strategy).balanceOf(address(this));

        /// @dev 2. Convert the strategy shares into base assets and add them all.
        assets = SimpleTokenizedStrategy(strategy).convertToAssets(strategySharesBalance);
    }

    function getMaxWithdrawable(address strategy) internal view returns (uint256 maxWithdrawableAmount) {
        maxWithdrawableAmount = SimpleTokenizedStrategy(strategy).maxWithdraw(address(this));
    }

    function depositFunds(DataTypes.StrategyState storage s, uint256 assets) internal {
        uint256 i = 0;
        uint256[] memory supplyQueue = s.supplyQueue;
        for (i; i < supplyQueue.length; ++i) {
            DataTypes.Strategy memory strategy = s.strategies[supplyQueue[i]];

            if (strategy.cap == 0) continue;

            // 1. Get supplied share balance in the strategy
            // 2. Convert it to supplied assets
            uint256 currentAssets = getAssetBalanceInStrategy(strategy.strategy);

            // 3. min(assets, (cap-currentAssets))
            uint256 amountToSupply = assets.min(strategy.cap.zeroFloorSub(currentAssets));

            // 4. Supply the assets.
            if (amountToSupply > 0) {
                _deposit(strategy.strategy, amountToSupply);
                assets = assets.zeroFloorSub(amountToSupply);
            }

            if (assets == 0) return;
        }

        if (assets != 0) revert Errors.AllCapsReached();
    }

    /**
     * @notice Withdraw funds from strategies based on `withdrawQueue`.
     * @param s Current Strategy State
     * @param assets Total assets to transfer outside of the vault to the user
     */
    function withdrawFunds(DataTypes.StrategyState storage s, uint256 assets) internal {
        uint256 i = 0;
        uint256[] memory withdrawQueue = s.withdrawQueue;
        for (i; i < withdrawQueue.length; i++) {
            DataTypes.Strategy memory strategy = s.strategies[withdrawQueue[i]];

            uint256 maxWithdrawable = getMaxWithdrawable(strategy.strategy);

            uint256 amountToWithdraw = maxWithdrawable.min(assets);

            if (amountToWithdraw > 0) {
                uint256 finalAmountWithdrawn = _withdraw(strategy.strategy, amountToWithdraw);

                assets = assets.zeroFloorSub(finalAmountWithdrawn);
            }

            if (assets == 0) return;
        }

        if (assets != 0) revert Errors.NotEnoughLiquidity();
    }

    function reallocateFunds(DataTypes.StrategyState storage s, DataTypes.Allocation[] memory allocations) internal {
        uint256 totalSupplied;
        uint256 totalWithdrawn;

        uint256 i = 0;
        for (i; i < allocations.length; i++) {
            DataTypes.Allocation memory allocation = allocations[i];
            DataTypes.Strategy memory strategy = s.strategies[allocation.index];

            uint256 currentBalance = getAssetBalanceInStrategy(strategy.strategy);
            uint256 newAllocation = allocation.amount;

            /// @dev If `newAllocation` is less than `currentBalance`, it means we need withdraw funds.
            uint256 toWithdraw = currentBalance.zeroFloorSub(newAllocation);

            if (toWithdraw > 0) {
                // withdrawing funds

                uint256 withdrawn = _withdraw(strategy.strategy, toWithdraw);

                totalWithdrawn = totalWithdrawn.rawAdd(withdrawn);

                //!TODO: emit event
            } else {
                /// @dev If `type(uint256).max` passed as `newAllocation` then all the funds remaining in `totalWithdrawn` will be supplied to the strategy.
                uint256 assetToSupply = newAllocation == type(uint256).max
                    ? totalWithdrawn.zeroFloorSub(totalSupplied)
                    : newAllocation.zeroFloorSub(currentBalance);

                if (assetToSupply == 0) continue;

                uint256 currentSupplyCap = strategy.cap;
                if (currentSupplyCap == 0) revert();

                if (currentBalance + assetToSupply > currentSupplyCap) revert();

                _deposit(strategy.strategy, assetToSupply);
                //!TODO: emit event

                totalSupplied = totalSupplied.rawAdd(assetToSupply);
            }
        }

        if (totalSupplied != totalWithdrawn) revert();
    }

    function _withdraw(address strategy, uint256 amount) internal returns (uint256 finalWithdrawn) {
        finalWithdrawn = SimpleTokenizedStrategy(strategy).withdraw(amount, address(this), address(this));
    }

    function _deposit(address strategy, uint256 amountToSupply) internal {
        SimpleTokenizedStrategy(strategy).deposit(amountToSupply, address(this));
    }

    function withdrawMaxFunds(address strategy, address asset) internal {
        uint256 maxWithdrawable = getMaxWithdrawable(strategy);

        SimpleTokenizedStrategy(strategy).withdraw(maxWithdrawable, address(this), address(this));

        strategy.safeApprove(asset, 0);
    }

    function emergencyWithdraw(DataTypes.StrategyState storage s) internal {
        uint256 i = 0;
        uint256[] memory withdrawQueue = s.withdrawQueue;
        for (i; i < withdrawQueue.length; i++) {
            uint256 maxWithdrawable =
                SimpleTokenizedStrategy(s.strategies[withdrawQueue[i]].strategy).maxWithdraw(address(this));

            if (maxWithdrawable == 0) continue;

            SimpleTokenizedStrategy(s.strategies[i].strategy).withdraw(maxWithdrawable, address(this), address(this));
        }
    }
}
