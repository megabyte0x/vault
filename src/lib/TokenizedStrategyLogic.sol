// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {DataTypes} from "./DataTypes.sol";
import {Helpers} from "./Helpers.sol";
import {Errors} from "./Errors.sol";
import {Events} from "./Events.sol";

import {SimpleTokenizedStrategy} from "../TokenizedStrategy/SimpleTokenizedStrategy.sol";

/// @title TokenizedStrategyLogic
/// @notice Library for interacting with tokenized strategies and managing fund flows
/// @dev Handles deposits, withdrawals, and reallocations across multiple tokenized strategies
/// @author megabyte0x.eth
library TokenizedStrategyLogic {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;
    using Helpers for DataTypes.StrategyState;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    /// @notice Retrieves the underlying asset address from a tokenized strategy
    /// @param strategy The address of the tokenized strategy
    /// @return asset The address of the underlying asset
    function getAsset(address strategy) internal view returns (address asset) {
        asset = SimpleTokenizedStrategy(strategy).asset();
    }

    /// @notice Returns the amount of assets deployed in a specific tokenized strategy
    /// @dev Converts strategy shares to underlying asset amount using ERC-4626 conversion
    /// @param strategy The address of the tokenized strategy
    /// @return assets The amount of underlying assets held by the strategy
    function getAssetBalanceInStrategy(address strategy) internal view returns (uint256 assets) {
        // Get the number of strategy shares held by this vault
        uint256 strategySharesBalance = SimpleTokenizedStrategy(strategy).balanceOf(address(this));

        // Convert strategy shares to underlying asset amount
        assets = SimpleTokenizedStrategy(strategy).convertToAssets(strategySharesBalance);
    }

    /// @notice Returns the maximum amount of assets that can be withdrawn from a strategy
    /// @dev Queries the strategy's maxWithdraw function for current withdrawal limit
    /// @param strategy The address of the tokenized strategy
    /// @return maxWithdrawableAmount The maximum withdrawable amount in underlying assets
    function getMaxWithdrawable(address strategy) internal view returns (uint256 maxWithdrawableAmount) {
        maxWithdrawableAmount = SimpleTokenizedStrategy(strategy).maxWithdraw(address(this));
    }

    /// @notice Deposits assets into strategies following the supply queue order
    /// @dev Distributes assets across strategies respecting allocation caps and queue priority
    /// @param s The strategy state storage reference
    /// @param assets The total amount of assets to deposit
    function depositFunds(DataTypes.StrategyState storage s, uint256 assets) internal {
        uint256 i = 0;
        uint256[] memory supplyQueue = s.supplyQueue;
        for (i; i < supplyQueue.length; ++i) {
            DataTypes.Strategy memory strategy = s.strategies[supplyQueue[i]];

            // Skip strategies with zero cap
            if (strategy.cap == 0) continue;

            // Get current asset balance in the strategy
            uint256 currentAssets = getAssetBalanceInStrategy(strategy.strategy);

            // Calculate available capacity: min(remaining assets, available cap)
            uint256 amountToSupply = assets.min(strategy.cap.zeroFloorSub(currentAssets));

            // Deposit available assets to the strategy
            if (amountToSupply > 0) {
                _deposit(strategy.strategy, amountToSupply);
                assets = assets.zeroFloorSub(amountToSupply);

                emit Events.SimpleVTS__DepositedInStrategy(supplyQueue[i], amountToSupply);
            }

            // Exit if all assets have been allocated
            if (assets == 0) return;
        }

        // Revert if assets remain after trying all strategies
        if (assets != 0) revert Errors.AllCapsReached();
    }

    /// @notice Withdraws assets from strategies following the withdraw queue order
    /// @dev Processes withdrawals across strategies until requested amount is obtained
    /// @param s The strategy state storage reference
    /// @param assets The total amount of assets to withdraw
    function withdrawFunds(DataTypes.StrategyState storage s, uint256 assets) internal {
        uint256 i = 0;
        uint256[] memory withdrawQueue = s.withdrawQueue;
        for (i; i < withdrawQueue.length; i++) {
            DataTypes.Strategy memory strategy = s.strategies[withdrawQueue[i]];

            // Get maximum withdrawable amount from this strategy
            uint256 maxWithdrawable = getMaxWithdrawable(strategy.strategy);

            // Withdraw the minimum of needed and available
            uint256 amountToWithdraw = maxWithdrawable.min(assets);

            if (amountToWithdraw > 0) {
                uint256 finalAmountWithdrawn = _withdraw(strategy.strategy, amountToWithdraw);

                assets = assets.zeroFloorSub(finalAmountWithdrawn);

                emit Events.SimpleVTS__WithdrewFromStrategy(withdrawQueue[i], finalAmountWithdrawn);
            }

            // Exit if all required assets have been withdrawn
            if (assets == 0) return;
        }

        // Revert if insufficient liquidity across all strategies
        if (assets != 0) revert Errors.NotEnoughLiquidity();
    }

    /// @notice Reallocates funds across strategies according to specified allocations
    /// @dev Processes withdrawals first, then deposits, ensuring total balance consistency
    /// @param s The strategy state storage reference
    /// @param allocations Array of allocation instructions specifying target amounts per strategy
    function reallocateFunds(DataTypes.StrategyState storage s, DataTypes.Allocation[] memory allocations) internal {
        uint256 totalSupplied;
        uint256 totalWithdrawn;

        uint256 i = 0;
        for (i; i < allocations.length; i++) {
            DataTypes.Allocation memory allocation = allocations[i];
            DataTypes.Strategy memory strategy = s.strategies[allocation.index];

            uint256 currentBalance = getAssetBalanceInStrategy(strategy.strategy);
            uint256 newAllocation = allocation.amount;

            // Calculate if we need to withdraw (current > target)
            uint256 toWithdraw = currentBalance.zeroFloorSub(newAllocation);

            if (toWithdraw > 0) {
                // Withdraw excess funds from strategy
                uint256 withdrawn = _withdraw(strategy.strategy, toWithdraw);

                totalWithdrawn += withdrawn;

                emit Events.SimpleVTS__WithdrewFromStrategy(allocation.index, withdrawn);
            } else {
                // Calculate assets to supply (target > current)
                // Special case: type(uint256).max means allocate all remaining withdrawn funds
                uint256 assetToSupply = newAllocation == type(uint256).max
                    ? totalWithdrawn.zeroFloorSub(totalSupplied)
                    : newAllocation.zeroFloorSub(currentBalance);

                if (assetToSupply == 0) continue;

                // Validate strategy cap constraints
                uint256 currentSupplyCap = strategy.cap;
                if (currentSupplyCap == 0) revert Errors.StrategyWithZeroCap(allocation.index);

                if (currentBalance + assetToSupply > currentSupplyCap) {
                    revert Errors.SupplyCapExceeded(allocation.index);
                }

                _deposit(strategy.strategy, assetToSupply);

                emit Events.SimpleVTS__DepositedInStrategy(allocation.index, assetToSupply);

                totalSupplied += assetToSupply;
            }
        }

        // Ensure reallocation maintains asset balance (what's withdrawn must equal what's deposited)
        if (totalSupplied != totalWithdrawn) revert Errors.InvalidReallocation();
    }

    /// @notice Withdraws all available funds from a specific strategy
    /// @dev Used when removing strategies or during emergency operations
    /// @param strategy The address of the strategy to withdraw from
    /// @param asset The address of the underlying asset for approval reset
    function withdrawMaxFunds(address strategy, address asset) internal {
        uint256 maxWithdrawable = getMaxWithdrawable(strategy);

        _withdraw(strategy, maxWithdrawable);

        // Reset asset approval for the strategy
        strategy.safeApprove(asset, 0);
    }

    /// @notice Emergency withdrawal of all funds from all strategies
    /// @dev Withdraws maximum available from each strategy in withdraw queue order
    /// @param s The strategy state storage reference
    function emergencyWithdraw(DataTypes.StrategyState storage s) internal {
        uint256 i = 0;
        uint256[] memory withdrawQueue = s.withdrawQueue;
        for (i; i < withdrawQueue.length; i++) {
            address strategyAddress = s.strategies[withdrawQueue[i]].strategy;
            uint256 maxWithdrawable = SimpleTokenizedStrategy(strategyAddress).maxWithdraw(address(this));

            // Skip strategies with no withdrawable balance
            if (maxWithdrawable == 0) continue;

            SimpleTokenizedStrategy(strategyAddress).withdraw(maxWithdrawable, address(this), address(this));
        }
    }

    /// @notice Internal function to deposit assets into a tokenized strategy
    /// @dev Calls the strategy's deposit function with vault as receiver
    /// @param strategy The address of the strategy to deposit into
    /// @param amountToSupply The amount of assets to deposit
    function _deposit(address strategy, uint256 amountToSupply) internal {
        SimpleTokenizedStrategy(strategy).deposit(amountToSupply, address(this));
    }

    /// @notice Internal function to withdraw assets from a tokenized strategy
    /// @dev Calls the strategy's withdraw function with vault as receiver and owner
    /// @param strategy The address of the strategy to withdraw from
    /// @param amount The amount of assets to withdraw
    /// @return finalWithdrawn The actual amount of assets withdrawn
    function _withdraw(address strategy, uint256 amount) internal returns (uint256 finalWithdrawn) {
        finalWithdrawn = SimpleTokenizedStrategy(strategy).withdraw(amount, address(this), address(this));
    }
}
