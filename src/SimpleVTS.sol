// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@solady/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

import {Errors} from "./lib/Errors.sol";
import {Events} from "./lib/Events.sol";
import {Helpers} from "./lib/Helpers.sol";
import {DataTypes} from "./lib/DataTypes.sol";
import {VaultStateLogic} from "./lib/VaultStateLogic.sol";
import {StrategyStateLogic} from "./lib/StrategyStateLogic.sol";
import {TokenizedStrategyLogic} from "./lib/TokenizedStrategyLogic.sol";

import {SimpleVTS__Storage} from "./SimpleVTS__Storage.sol";

/// @title SimpleVTS (Simple Vault with Tokenized Strategies)
/// @notice Advanced ERC-4626 compliant vault with modular tokenized strategy support
/// @dev Extends Solady's ERC4626 with role-based access control, multiple strategies, and advanced allocation management
/// @custom:security Uses reentrancy guards and access control for secure operations
/// @author megabyte0x.eth

// aderyn-ignore-next-line(centralization-risk)
contract SimpleVTS is SimpleVTS__Storage, ERC4626, AccessControl, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;
    using TokenizedStrategyLogic for DataTypes.StrategyState;
    using Helpers for DataTypes.StrategyState;
    using StrategyStateLogic for DataTypes.StrategyState;
    using VaultStateLogic for DataTypes.VaultState;

    /**
     * @notice Initializes the vault with the specified underlying asset
     * @param _asset The address of the ERC20 token to be used as the underlying asset
     * @param _admin The address which will act as the MAIN ADMIN of the vault.
     */
    constructor(address _asset, address _admin) SimpleVTS__Storage(_asset) {
        if (_admin == address(0)) revert Errors.ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /*
       _____      _                        _   _____                 _   _
      | ____|_  _| |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      |  _| \ \/ / __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      | |___ >  <| ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_____/_/\_\\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Sets the entry fee for deposits
    /// @param newEntryFee The new entry fee in basis points (e.g., 50 = 0.5%)
    function setEntryFee(uint256 newEntryFee) external onlyRole(MANAGER) {
        s_vault.updateEntryFee(newEntryFee);

        emit Events.SimpleVTS__EntryFeeUpdated(newEntryFee);
    }

    /// @notice Sets the exit fee for withdrawals
    /// @param newExitFee The new exit fee in basis points (e.g., 100 = 1%)
    function setExitFee(uint256 newExitFee) external onlyRole(MANAGER) {
        s_vault.updateExitFee(newExitFee);

        emit Events.SimpleVTS__ExitFeeUpdated(newExitFee);
    }

    /// @notice Sets the address that will receive collected fees
    /// @param newFeeRecipient The new fee recipient address (cannot be zero address)
    function setFeeRecipient(address newFeeRecipient) external onlyRole(MANAGER) {
        if (newFeeRecipient == address(0)) revert Errors.ZeroAddress();

        s_vault.updateFeeRecipient(newFeeRecipient);

        emit Events.SimpleVTS__FeeRecipientUpdated(newFeeRecipient);
    }

    /// @notice Adds a new tokenized strategy to the vault
    /// @dev Only callable by CURATOR role. Strategy must be compatible with vault asset
    /// @param strategy The address of the tokenized strategy contract to add
    /// @param cap The maximum amount of assets this strategy can hold
    function addStrategy(address strategy, uint256 cap) external onlyRole(CURATOR) {
        s_strategy.validateStrategyAddition(strategy, i_asset, MAX_STRATEGIES);

        s_strategy.addStrategy(strategy, cap);

        i_asset.safeApprove(strategy, type(uint256).max);

        emit Events.SimpleVTS__TokenizedStrategyAdded(strategy, cap);
    }

    /// @notice Changes the asset allocation cap for an existing strategy
    /// @dev Only callable by ALLOCATOR role. Must validate strategy exists
    /// @param strategy The address of the strategy to modify
    /// @param newCap The new maximum amount of assets this strategy can hold
    function changeStrategyCap(address strategy, uint256 newCap) external onlyRole(ALLOCATOR) {
        s_strategy.validateCapChange(strategy, newCap);

        s_strategy.changeCap(strategy, newCap);

        emit Events.SimpleVTS__CapUpdated(strategy, newCap);
    }

    /// @notice Reallocates funds across strategies according to specified allocations
    /// @dev Only callable by ALLOCATOR role. Validates total allocations and asset availability
    /// @param allocations Array of allocation instructions specifying strategy and amount changes
    function reallocateFunds(DataTypes.Allocation[] calldata allocations) external onlyRole(ALLOCATOR) {
        s_strategy.validateReallocateFunds(totalAssets(), i_asset);

        s_strategy.reallocateFunds(allocations);

        emit Events.SimpleVTS__FundsReallocated();
    }

    /// @notice Emergency function to withdraw all funds from all strategies back to the vault
    /// @dev Only callable by MANAGER role. Used in emergency situations to secure assets
    function emergencyWithdrawFunds() external onlyRole(MANAGER) {
        s_strategy.emergencyWithdraw();

        emit Events.SimpleVTS__EmergencyWithdrawFunds();
    }

    /// @notice Updates the order in which strategies receive deposits
    /// @dev Only callable by ALLOCATOR role. Queue determines priority for fund deployment
    /// @param newSupplyQueue Array of strategy indices in desired supply order
    function updateSupplyQueue(uint256[] memory newSupplyQueue) external onlyRole(ALLOCATOR) {
        s_strategy.validateNewSupplyQueue(newSupplyQueue, MAX_STRATEGIES);

        s_strategy.updateSupplyQueue(newSupplyQueue);

        emit Events.SimpleVTS__SupplyQueueUpdated(newSupplyQueue);
    }

    /// @notice Updates the order in which strategies are drained for withdrawals
    /// @dev Only callable by ALLOCATOR role. Queue determines priority for fund withdrawal
    /// @param newWithdrawQueue Array of strategy indices in desired withdrawal order
    function updateWithdrawQueue(uint256[] memory newWithdrawQueue) external onlyRole(ALLOCATOR) {
        s_strategy.validateNewWithdrawQueue(newWithdrawQueue);

        s_strategy.updateWithdrawQueue(newWithdrawQueue);

        emit Events.SimpleVTS__WithdrawQueueUpdated(newWithdrawQueue);
    }

    /*
       ____        _     _ _        _____                 _   _
      |  _ \ _   _| |__ | (_) ___  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      | |_) | | | | '_ \| | |/ __| | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      |  __/| |_| | |_) | | | (__  |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_|    \__,_|_.__/|_|_|\___| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Returns the name of the vault token
    /// @inheritdoc ERC20
    /// @return The vault token name
    function name() public pure override returns (string memory) {
        return "Simple Vault w/ Tokenized Strategy";
    }

    /// @notice Returns the symbol of the vault token
    /// @inheritdoc ERC20
    /// @return The vault token symbol
    function symbol() public pure override returns (string memory) {
        return "SVTS";
    }

    /// @notice Returns the address of the underlying asset
    /// @inheritdoc ERC4626
    /// @return The address of the underlying ERC20 token
    function asset() public view override returns (address) {
        return i_asset;
    }

    /// @notice Previews the amount of shares that would be minted for a deposit
    /// @inheritdoc ERC4626
    /// @dev Deducts entry fees from assets before calculating shares
    /// @param assets The amount of assets to be deposited
    /// @return shares The amount of shares that would be minted (after fees)
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        uint256 fee = _feeOnTotal(assets, getEntryFee());
        return super.previewDeposit(assets.rawSub(fee));
    }

    /// @notice Previews the amount of assets needed to mint a specific amount of shares
    /// @inheritdoc ERC4626
    /// @dev Adds entry fees to the required assets
    /// @param shares The amount of shares to be minted
    /// @return assets The total amount of assets needed (including fees)
    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewMint(shares);
        return (assets.rawAdd(_feeOnRaw(assets, getEntryFee())));
    }

    /// @notice Previews the amount of shares needed to withdraw a specific amount of assets
    /// @inheritdoc ERC4626
    /// @dev Deducts exit fees from assets before calculating shares
    /// @param assets The amount of assets to be withdrawn
    /// @return shares The amount of shares that need to be burned
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        uint256 fee = _feeOnRaw(assets, getExitFee());
        return super.previewWithdraw(assets.rawAdd(fee));
    }

    /// @notice Previews the amount of assets that would be withdrawn for redeeming shares
    /// @inheritdoc ERC4626
    /// @dev Adds exit fees to the assets calculation
    /// @param shares The amount of shares to be redeemed
    /// @return assets The total amount of assets that would be withdrawn (including fees)
    function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewRedeem(shares);
        return (assets.rawSub(_feeOnTotal(assets, getExitFee())));
    }

    /// @notice Returns the total amount of assets under management
    /// @inheritdoc ERC4626
    /// @dev Delegates to the strategy contract to calculate total assets across all positions
    /// @return assets The total amount of underlying assets managed by the vault
    function totalAssets() public view override returns (uint256 assets) {
        uint256 i = 0;

        for (i; i < s_strategy.totalStrategies; i++) {
            assets = assets.rawAdd(TokenizedStrategyLogic.getAssetBalanceInStrategy(s_strategy.strategies[i].strategy));
        }
    }

    /**
     * @notice Returns max amount of assets any `user` can deposit.
     * @dev It returns the sum of remaining `cap` of each `strategy`.
     * @param user Address of the user
     */
    function maxDeposit(address user) public view override returns (uint256 maxAssets) {
        uint256 i = 0;
        uint256[] memory supplyQueue = s_strategy.supplyQueue;
        for (i; i < supplyQueue.length; i++) {
            DataTypes.Strategy memory strategy = s_strategy.strategies[supplyQueue[i]];

            uint256 cap = strategy.cap;

            if (cap == 0) continue;

            uint256 currentBalance = TokenizedStrategyLogic.getAssetBalanceInStrategy(strategy.strategy);

            maxAssets = maxAssets.rawAdd(cap.zeroFloorSub(currentBalance));
        }
    }

    /**
     * @notice Returns max amount of assets `user` can withdraw after applicable `fee`.
     * @param user Address of the user
     */
    function maxWithdraw(address user) public view override returns (uint256 maxAssets) {
        uint256 balanceOfUser = convertToAssets(balanceOf(user));
        uint256 fee = getExitFee();

        if (fee == 0) return balanceOfUser;

        uint256 feeOnWithdraw = _feeOnTotal(balanceOfUser, fee);

        maxAssets = balanceOfUser.rawSub(feeOnWithdraw);
    }

    /// @notice Returns the current entry fee in basis points
    /// @return The entry fee charged on deposits (in basis points)
    function getEntryFee() public view returns (uint256) {
        return s_vault.entryFee;
    }

    /// @notice Returns the internal index of a strategy in the strategies array
    /// @param strategy The address of the strategy to look up
    /// @return index The index of the strategy in the strategies array
    function getStrategyIndex(address strategy) external view returns (uint256 index) {
        return s_strategy.getStrategyIndex(strategy);
    }

    /// @notice Returns the current exit fee in basis points
    /// @return The exit fee charged on withdrawals (in basis points)
    function getExitFee() public view returns (uint256) {
        return s_vault.exitFee;
    }

    /// @notice Returns the current fee recipient address
    /// @return The address that receives collected entry and exit fees
    function getFeeRecipient() external view returns (address) {
        return s_vault.feeRecipient;
    }

    /// @notice Returns detailed information about a strategy
    /// @param strategyIndex The index of the strategy in the strategies array
    /// @return strategy The strategy struct containing address and allocation cap
    function getStrategyDetails(uint256 strategyIndex) external view returns (DataTypes.Strategy memory strategy) {
        strategy = s_strategy.strategies[strategyIndex];
    }

    /// @notice Returns the total number of strategies added to the vault
    /// @return The count of strategies currently managed by the vault
    function getTotalStrategies() external view returns (uint256) {
        return s_strategy.totalStrategies;
    }

    /// @notice Returns the amount of assets currently deployed in a specific strategy
    /// @param strategy The address of the strategy to query
    /// @return assets The amount of underlying assets held by the specified strategy
    function getAssetInStrategy(address strategy) external view returns (uint256 assets) {
        assets = TokenizedStrategyLogic.getAssetBalanceInStrategy(
            s_strategy.strategies[s_strategy.getStrategyIndex(strategy)].strategy
        );
    }

    /*
       ___       _                        _   _____                 _   _
      |_ _|_ __ | |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
       | || '_ \| __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
       | || | | | ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |___|_| |_|\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /**
     * @notice Deposit the supplied funds, after applicable `fee`, in the strategies.
     * @param assets Amount of base `asset`
     * @param shares Amount of shares.
     */
    function _afterDeposit(uint256 assets, uint256 shares) internal override {
        uint256 fee = getEntryFee();

        if (fee != 0) {
            uint256 feeAmount = _feeOnTotal(assets, fee);

            // Transfer entry fee to fee recipient (if fee exists and recipient is not this contract)
            if (feeAmount > 0 && s_vault.feeRecipient != address(this)) {
                i_asset.safeTransfer(s_vault.feeRecipient, feeAmount);
            }

            assets = assets.rawSub(feeAmount);
        }

        s_strategy.depositFunds(assets);
    }

    /**
     * @notice Withdraw funds from the strategies, and deduct applicable `fee`.
     * @param assets Amount of base `asset`
     * @param shares Amount of shares.
     */
    function _beforeWithdraw(uint256 assets, uint256 shares) internal override nonReentrant {
        // Withdraw assets from strategies
        s_strategy.withdrawFunds(assets);

        uint256 fee = getExitFee();
        if (fee != 0) {
            uint256 feeAmount = _feeOnRaw(assets, fee);

            // Transfer exit fee to fee recipient (if fee exists and recipient is not this contract)
            if (feeAmount > 0 && s_vault.feeRecipient != address(this)) {
                i_asset.safeTransfer(s_vault.feeRecipient, feeAmount);
            }
        }
    }

    /// @notice Returns the number of decimals used by the underlying asset
    /// @inheritdoc ERC4626
    /// @dev Used internally for precise share calculations
    /// @return The number of decimals of the underlying asset
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(i_asset).decimals();
    }

    /// @notice Calculates the fees that should be added to an amount that does not already include fees
    /// @dev Used in {ERC4626-mint} and {ERC4626-withdraw} operations
    /// @param assets The base amount of assets (without fees)
    /// @param feeBasisPoints The fee rate in basis points
    /// @return The calculated fee amount
    function _feeOnRaw(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, BASIS_POINT_SCALE);
    }

    /// @notice Calculates the fee portion of an amount that already includes fees
    /// @dev Used in {ERC4626-deposit} and {ERC4626-redeem} operations
    /// @param assets The total amount of assets (including fees)
    /// @param feeBasisPoints The fee rate in basis points
    /// @return The calculated fee amount
    function _feeOnTotal(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, feeBasisPoints + BASIS_POINT_SCALE);
    }
}

