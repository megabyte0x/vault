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

    function getAssetBalanceInStrategy(address strategy) internal view returns (uint256 assets) {
        /// @dev 1. Get the number of strategy shares.
        uint256 strategySharesBalance = SimpleTokenizedStrategy(strategy).balanceOf(address(this));

        /// @dev 2. Convert the strategy shares into base assets and add them all.
        assets = SimpleTokenizedStrategy(strategy).convertToAssets(strategySharesBalance);
    }

    function getMaxWithdrawable(address strategy) internal view returns (uint256 maxWithdrawableAmount) {
        maxWithdrawableAmount = SimpleTokenizedStrategy(strategy).maxWithdraw(address(this));
    }

    function withdrawMaxFunds(address strategy) internal {
        uint256 maxWithdrawable = getMaxWithdrawable(strategy);

        SimpleTokenizedStrategy(strategy).withdraw(maxWithdrawable, address(this), address(this));
    }

    function getAsset(address strategy) internal view returns (address asset) {
        asset = SimpleTokenizedStrategy(strategy).asset();
    }

    function reallocateFunds(DataTypes.StrategyState storage s, address asset) internal {
        uint256 currentTotalAssets;

        uint256 i = 0;

        uint256 currentIdleAssetBalance = asset.balanceOf(address(this));
        uint256[] memory currentAssetsBalances = new uint256[](s.totalStrategies);

        uint256 totalAssetBalanceAcrossStrategies;

        for (i; i < s.totalStrategies; i++) {
            currentAssetsBalances[i] = getAssetBalanceInStrategy(s.strategies[i].strategy);
            totalAssetBalanceAcrossStrategies = totalAssetBalanceAcrossStrategies.rawAdd(currentAssetsBalances[i]);
        }

        currentTotalAssets = totalAssetBalanceAcrossStrategies.rawAdd(currentIdleAssetBalance);

        /// @dev Vault is empty, no funds to allocate.
        if (currentTotalAssets == 0) return;

        uint256 targetIdleAssetBalance = currentTotalAssets.mulDiv(s.minimumIdleAssets, BASIS_POINT_SCALE);

        i = 0;
        /**
         * @dev This loop withdraw assets if they are in excess.
         * This condition occurs when Price per share increases.
         */
        for (i; i < s.totalStrategies; i++) {
            uint256 targetAssetBalance = currentTotalAssets.mulDiv(s.strategies[i].allocation, BASIS_POINT_SCALE);
            if (currentAssetsBalances[i] > targetAssetBalance) {
                uint256 excess = currentAssetsBalances[i].rawSub(targetAssetBalance);
                uint256 maxWithdrawable = SimpleTokenizedStrategy(s.strategies[i].strategy).maxWithdraw(address(this));

                uint256 amountToWithdraw = excess.min(maxWithdrawable);

                if (amountToWithdraw == 0) continue;

                SimpleTokenizedStrategy(s.strategies[i].strategy)
                    .withdraw(amountToWithdraw, address(this), address(this));

                currentIdleAssetBalance = currentIdleAssetBalance.rawAdd(amountToWithdraw);
                currentAssetsBalances[i] = currentAssetsBalances[i].rawSub(amountToWithdraw);
            }
        }
        uint256 deployable;

        if (currentIdleAssetBalance >= targetIdleAssetBalance) {
            deployable = currentIdleAssetBalance.rawSub(targetIdleAssetBalance);

            i = 0;
            for (i; i < s.totalStrategies; i++) {
                uint256 targetAssetBalance = currentTotalAssets.mulDiv(s.strategies[i].allocation, BASIS_POINT_SCALE);
                if (currentAssetsBalances[i] < targetAssetBalance) {
                    uint256 need = targetAssetBalance.rawSub(currentAssetsBalances[i]);

                    uint256 amountToDeposit = need.min(deployable);

                    if (amountToDeposit == 0) break;

                    uint256 sharesReceived =
                        SimpleTokenizedStrategy(s.strategies[i].strategy).deposit(amountToDeposit, address(this));

                    deployable = deployable.rawSub(amountToDeposit);
                    currentAssetsBalances[i] = currentAssetsBalances[i].rawAdd(
                        SimpleTokenizedStrategy(s.strategies[i].strategy).convertToAssets(sharesReceived)
                    );
                }
            }
        }
    }

    /**
     * @notice Withdraw funds from strategy if the `currentIdleAssetBalance` is not enough to cover the `amountToTransfer`.
     * @dev Withdraw is a three step process:
     * 1. Checks if `currentIdleAssetBalance` is enough, if yes, then return. If no, then next steps are executed.
     * 2. Check for all the strategies. If any strategy have excess funds, withdraw from that strategy. If the total funds withdraw covers the `amountToTransfer` and leave the `currentIdleAssetBalance` equivalent to the `targetIdleAssetBalance`, then return else next step is executed.
     * 3. Divide the remaining funds required to cover the `targetIdleAssetBalance` and `amountToWithdraw` equally between each `strategy` and withdraw the funds from them. If the funds cover, then return else revert.
     * @param s Current Strategy State
     * @param amountToTransfer Total assets to transfer outside of the vault to the user
     * @param asset Asset Address
     */
    function withdrawFunds(DataTypes.StrategyState storage s, uint256 amountToTransfer, address asset) internal {
        uint256 currentIdleAssetBalance = asset.balanceOf(address(this));
        uint256 currentTotalAssets;

        uint256 i = 0;

        uint256[] memory currentAssetsBalances = new uint256[](s.totalStrategies);

        uint256 totalAssetBalanceAcrossStrategies;

        for (i; i < s.totalStrategies; i++) {
            currentAssetsBalances[i] = getAssetBalanceInStrategy(s.strategies[i].strategy);
            totalAssetBalanceAcrossStrategies = totalAssetBalanceAcrossStrategies.rawAdd(currentAssetsBalances[i]);
        }

        currentTotalAssets = totalAssetBalanceAcrossStrategies.rawAdd(currentIdleAssetBalance);

        uint256 requireIdleAssetBalance =
            currentTotalAssets.mulDiv(s.minimumIdleAssets, BASIS_POINT_SCALE).rawAdd(amountToTransfer);

        if (currentIdleAssetBalance >= requireIdleAssetBalance) return;

        uint256 need = requireIdleAssetBalance - currentIdleAssetBalance;

        i = 0;
        /**
         * @dev This loop withdraw assets if they are in excess.
         * This condition occurs when Price per share increases.
         */
        for (i; i < s.totalStrategies; i++) {
            uint256 targetAssetBalance = currentTotalAssets.mulDiv(s.strategies[i].allocation, BASIS_POINT_SCALE);
            if (currentAssetsBalances[i] > targetAssetBalance) {
                uint256 excess = currentAssetsBalances[i].rawSub(targetAssetBalance);
                uint256 maxWithdrawable = SimpleTokenizedStrategy(s.strategies[i].strategy).maxWithdraw(address(this));

                uint256 amountToWithdraw = maxWithdrawable.min(excess.min(need));

                if (amountToWithdraw == 0) continue;

                SimpleTokenizedStrategy(s.strategies[i].strategy)
                    .withdraw(amountToWithdraw, address(this), address(this));

                currentIdleAssetBalance = currentIdleAssetBalance.rawAdd(amountToWithdraw);
                need = need.rawSub(amountToWithdraw);
            }

            if (currentIdleAssetBalance >= requireIdleAssetBalance) {
                return;
            }
        }

        i = 0;
        for (i; i < s.totalStrategies; i++) {
            uint256 maxWithdrawable = SimpleTokenizedStrategy(s.strategies[i].strategy).maxWithdraw(address(this));

            uint256 amountToWithdraw = maxWithdrawable.min(need);

            if (amountToWithdraw == 0) continue;

            SimpleTokenizedStrategy(s.strategies[i].strategy).withdraw(amountToWithdraw, address(this), address(this));

            currentIdleAssetBalance = currentIdleAssetBalance.rawAdd(amountToWithdraw);
            need = need.rawSub(amountToWithdraw);

            if (currentIdleAssetBalance >= requireIdleAssetBalance || need == 0) {
                return;
            }
        }

        revert Errors.NotEnoughFundsAvailable();
    }
}
