// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

import {DataTypes} from "./lib/DataTypes.sol";
import {Errors} from "./lib/Errors.sol";
import {Helpers} from "./lib/Helpers.sol";
import {StrategyStateLogic} from "./lib/StrategyStateLogic.sol";
import {VaultStateLogic} from "./lib/VaultStateLogic.sol";
import {TokenizedStrategyLogic} from "./lib/TokenizedStrategyLogic.sol";
import {SimpleVaultWithTokenizedStrategyStorage} from "./SimpleVaultWithTokenizedStrategyStorage.sol";

/// @title SimpleVault
/// @notice An ERC-4626 compliant vault that integrates with DeFi protocols through a pluggable strategy
/// @dev Extends Solady's ERC4626 implementation with entry/exit fees and strategy delegation
/// @author megabyte0x.eth

// aderyn-ignore-next-line(centralization-risk)
contract SimpleVaultWithTokenizedStrategy is SimpleVaultWithTokenizedStrategyStorage, ERC4626, AccessControl {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;
    using Helpers for DataTypes.StrategyState;
    using StrategyStateLogic for DataTypes.StrategyState;
    using TokenizedStrategyLogic for DataTypes.StrategyState;
    using VaultStateLogic for DataTypes.VaultState;

    /// @notice Initializes the vault with the specified underlying asset
    /// @param asset_ The address of the ERC20 token to be used as the underlying asset
    constructor(address asset_) SimpleVaultWithTokenizedStrategyStorage(asset_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

        emit SimpleVault__EntryFeeUpdated(newEntryFee);
    }

    /// @notice Sets the exit fee for withdrawals
    /// @param newExitFee The new exit fee in basis points (e.g., 100 = 1%)
    function setExitFee(uint256 newExitFee) external onlyRole(MANAGER) {
        s_vault.updateExitFee(newExitFee);

        emit SimpleVault__ExitFeeUpdated(newExitFee);
    }

    /// @notice Sets the address that will receive collected fees
    /// @param newFeeRecipient The new fee recipient address (cannot be zero address)
    function setFeeRecipient(address newFeeRecipient) external onlyRole(MANAGER) {
        if (newFeeRecipient == address(0)) revert Errors.ZeroAddress();

        s_vault.updateFeeRecipient(newFeeRecipient);

        emit SimpleVault__FeeRecipientUpdated(newFeeRecipient);
    }

    function setMinimumIdleAssets(uint256 newMinimumIdleAssets) external onlyRole(CURATOR) {
        s_strategy.changeMimimumIdleAssets(newMinimumIdleAssets);

        emit SimpleVault__MinimumIdleAssetsUpdated(newMinimumIdleAssets);
    }

    function addStrategy(address strategy, uint256 allocation) external onlyRole(CURATOR) {
        s_strategy.validateStrategyAddition(strategy, allocation, i_asset, MAX_STRATEGIES);

        s_strategy.addStrategy(strategy, allocation);

        i_asset.safeApprove(strategy, type(uint256).max);

        s_strategy.reallocateFunds(i_asset);

        emit SimpleVault__TokenizedStrategyAdded(strategy, allocation);
    }

    function removeStrategy(address strategy) external onlyRole(CURATOR) {
        s_strategy.validateStrategyRemoval(strategy);

        TokenizedStrategyLogic.withdrawMaxFunds(strategy);

        s_strategy.removeStrategy(strategy);

        s_strategy.reallocateFunds(i_asset);

        emit SimpleVault__TokenizedStrategyRemoved(strategy);
    }

    function changeStrategyAllocation(address strategy, uint256 newAllocation) external onlyRole(ALLOCATOR) {
        s_strategy.validateAllocationChange(strategy, newAllocation);

        s_strategy.changeAllocation(strategy, newAllocation);

        s_strategy.reallocateFunds(i_asset);

        emit SimpleVault__AllocationUpdated(strategy, newAllocation);
    }

    function reallocateFunds() external onlyRole(ALLOCATOR) {
        s_strategy.validateReallocateFunds(totalAssets(), i_asset);

        s_strategy.reallocateFunds(i_asset);

        emit SimpleVault__FundsReallocated();
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

        assets = assets.rawAdd(ERC20(i_asset).balanceOf(address(this)));
    }

    function maxWithdraw(address user) public view override returns (uint256 maxAssets) {
        uint256 balanceOfUser = convertToAssets(balanceOf(user));

        uint256 feeOnWithdraw = _feeOnTotal(balanceOfUser, getExitFee());

        maxAssets = balanceOfUser.rawSub(feeOnWithdraw);
    }

    /// @notice Returns the current entry fee in basis points
    /// @return The entry fee charged on deposits (in basis points)
    function getEntryFee() public view returns (uint256) {
        return s_vault.entryFee;
    }

    function getStrategyIndex(address strategy) external view returns (uint256 index) {
        uint256 ip1 = s_strategy.strategyToIndex[strategy];
        if (ip1 == 0) revert Errors.StrategyNotFound();
        index = ip1 - 1;
    }

    /// @notice Returns the current exit fee in basis points
    /// @return The exit fee charged on withdrawals (in basis points)
    function getExitFee() public view returns (uint256) {
        return s_vault.exitFee;
    }

    function getFeeRecipient() external view returns (address) {
        return s_vault.feeRecipient;
    }

    function getStrategyDetails(uint256 strategyIndex) external view returns (DataTypes.Strategy memory strategy) {
        strategy = s_strategy.strategies[strategyIndex];
    }

    function getMinimumIdleAssets() external view returns (uint256) {
        return s_strategy.minimumIdleAssets;
    }

    function getTotalStrategies() external view returns (uint256) {
        return s_strategy.totalStrategies;
    }

    /*
       ___       _                        _   _____                 _   _
      |_ _|_ __ | |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
       | || '_ \| __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
       | || | | | ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |___|_| |_|\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Internal function to handle deposits
    /// @inheritdoc ERC4626
    /// @dev Transfers entry fees to fee recipient and supplies remaining assets to strategy
    /// @param by The address initiating the deposit
    /// @param to The address receiving the shares
    /// @param assets The total amount of assets being deposited
    /// @param shares The amount of shares being minted
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        super._deposit(by, to, assets, shares);

        uint256 fee = _feeOnTotal(assets, getEntryFee());

        // Transfer entry fee to fee recipient (if fee exists and recipient is not this contract)
        if (fee > 0 && s_vault.feeRecipient != address(this)) {
            i_asset.safeTransfer(s_vault.feeRecipient, fee);
        }
    }

    /// @notice Internal function to handle withdrawals
    /// @inheritdoc ERC4626
    /// @dev Withdraws assets from strategy, transfers exit fees, and processes withdrawal
    /// @param by The address initiating the withdrawal
    /// @param to The address receiving the assets
    /// @param owner The address owning the shares being burned
    /// @param assets The total amount of assets being withdrawn
    /// @param shares The amount of shares being burned
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        uint256 fee = _feeOnRaw(assets, getExitFee());

        // Transfer exit fee to fee recipient (if fee exists and recipient is not this contract)
        if (fee > 0 && s_vault.feeRecipient != address(this)) {
            i_asset.safeTransfer(s_vault.feeRecipient, fee);
        }

        uint256 assetsToTransfer = assets.rawSub(fee);

        // Withdraw assets from strategy (if required)
        s_strategy.withdrawFunds(assetsToTransfer, i_asset);

        // Complete the withdrawal process
        super._withdraw(by, to, owner, assetsToTransfer, shares);
    }

    /// @notice Returns the number of decimals used by the underlying asset
    /// @inheritdoc ERC4626
    /// @dev Used internally for precise share calculations
    /// @return The number of decimals of the underlying asset
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(i_asset).decimals();
    }

    /// @dev Calculates the fees that should be added to an amount `assets` that does not already include fees.
    /// Used in {ERC4626-mint} and {ERC4626-withdraw} operations.
    function _feeOnRaw(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, BASIS_POINT_SCALE);
    }

    /// @dev Calculates the fee part of an amount `assets` that already includes fees.
    /// Used in {ERC4626-deposit} and {ERC4626-redeem} operations.
    function _feeOnTotal(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, feeBasisPoints + BASIS_POINT_SCALE);
    }
}

