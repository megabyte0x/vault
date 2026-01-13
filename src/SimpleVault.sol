// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {Errors} from "./lib/Errors.sol";
import {ISimpleStrategy} from "./interfaces/ISimpleStrategy.sol";

/// @title SimpleVault
/// @notice An ERC-4626 compliant vault that integrates with DeFi protocols through a pluggable strategy
/// @dev Extends Solady's ERC4626 implementation with entry/exit fees and strategy delegation
/// @author megabyte0x.eth
contract SimpleVault is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @notice Emitted when the entry fee is updated
    /// @param newEntryFee The new entry fee in basis points
    event SimpleVault__EntryFeeUpdated(uint256 newEntryFee);

    /// @notice Emitted when the exit fee is updated
    /// @param newExitFee The new exit fee in basis points
    event SimpleVault__ExitFeeUpdated(uint256 newExitFee);

    /// @notice Emitted when the fee recipient address is updated
    /// @param newFeeRecipient The new address that will receive fees
    event SimpleVault__FeeRecipientUpdated(address newFeeRecipient);

    /// @notice Emitted when the strategy contract is updated
    /// @param newStrategy The new strategy contract address
    event SimpleVault__StrategyUpdated(address newStrategy);

    /// @notice The underlying asset that the vault accepts (immutable)
    address internal immutable i_asset;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 private constant BASIS_POINT_SCALE = 1e4;

    /// @notice Entry fee charged on deposits, expressed in basis points
    uint256 private s_entryFee;

    /// @notice Exit fee charged on withdrawals, expressed in basis points
    uint256 private s_exitFee;

    /// @notice Address that receives collected fees
    address private s_feeRecipient;

    /// @notice The strategy contract that manages yield generation
    ISimpleStrategy private s_strategy;

    /// @notice Initializes the vault with the specified underlying asset
    /// @param asset_ The address of the ERC20 token to be used as the underlying asset
    constructor(address asset_) {
        if (asset_ == address(0)) revert Errors.ZeroAddress();
        i_asset = asset_;
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
    //! TODO: Add access control modifiers
    function setEntryFee(uint256 newEntryFee) external {
        s_entryFee = newEntryFee;

        emit SimpleVault__EntryFeeUpdated(newEntryFee);
    }

    /// @notice Sets the exit fee for withdrawals
    /// @param newExitFee The new exit fee in basis points (e.g., 100 = 1%)
    //! TODO: Add access control modifiers
    function setExitFee(uint256 newExitFee) external {
        s_exitFee = newExitFee;

        emit SimpleVault__ExitFeeUpdated(newExitFee);
    }

    /// @notice Sets the address that will receive collected fees
    /// @param newFeeRecipient The new fee recipient address (cannot be zero address)
    //! TODO: Add access control modifiers
    function setFeeRecipient(address newFeeRecipient) external {
        if (newFeeRecipient == address(0)) revert Errors.ZeroAddress();

        s_feeRecipient = newFeeRecipient;

        emit SimpleVault__FeeRecipientUpdated(newFeeRecipient);
    }

    /// @notice Updates the strategy contract used for yield generation
    /// @dev Withdraws funds from current strategy before switching to new one
    /// @param newStrategy The address of the new strategy contract (cannot be zero address)
    //! TODO: Add access control modifiers
    function setStrategy(address newStrategy) external {
        if (newStrategy == address(0)) revert Errors.ZeroAddress();

        // Withdraw all funds from current strategy if one exists
        if (address(s_strategy) != address(0) && s_strategy.getTotalBalanceInMarkets() > 0) {
            s_strategy.withdrawFunds();
        }

        // Approve new strategy to spend vault's assets
        i_asset.safeApprove(newStrategy, type(uint256).max);

        s_strategy = ISimpleStrategy(newStrategy);

        emit SimpleVault__StrategyUpdated(newStrategy);
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
        return "Simple Vault";
    }

    /// @notice Returns the symbol of the vault token
    /// @inheritdoc ERC20
    /// @return The vault token symbol
    function symbol() public pure override returns (string memory) {
        return "SV";
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
        assets = s_strategy.totalAssets();
    }

    /// @notice Returns the maximum amount of assets that can be withdrawn by a user
    /// @inheritdoc ERC4626
    /// @dev Calculates withdrawable amount after deducting exit fees
    /// @param user The address of the user
    /// @return maxAssets The maximum amount of assets that can be withdrawn (after fees)
    function maxWithdraw(address user) public view override returns (uint256 maxAssets) {
        uint256 balanceOfUser = convertToAssets(balanceOf(user));

        uint256 feeOnWithdraw = _feeOnTotal(balanceOfUser, getExitFee());

        maxAssets = balanceOfUser.rawSub(feeOnWithdraw);
    }

    /// @notice Returns the current entry fee in basis points
    /// @return The entry fee charged on deposits (in basis points)
    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }

    /// @notice Returns the current exit fee in basis points
    /// @return The exit fee charged on withdrawals (in basis points)
    function getExitFee() public view returns (uint256) {
        return s_exitFee;
    }

    /// @notice Returns the current fee recipient address
    /// @return The address that receives collected fees
    function getFeeRecipient() external view returns (address) {
        return s_feeRecipient;
    }

    /// @notice Returns the current strategy contract address
    /// @return The address of the strategy contract managing yield generation
    function getStrategy() external view returns (address) {
        return address(s_strategy);
    }

    /*
       ___       _                        _   _____                 _   _
      |_ _|_ __ | |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
       | || '_ \| __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
       | || | | | ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |___|_| |_|\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Returns the number of decimals used by the underlying asset
    /// @inheritdoc ERC4626
    /// @dev Used internally for precise share calculations
    /// @return The number of decimals of the underlying asset
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(i_asset).decimals();
    }

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
        if (fee > 0 && s_feeRecipient != address(this)) {
            i_asset.safeTransfer(s_feeRecipient, fee);
        }

        // Supply remaining assets to strategy for yield generation
        s_strategy.supply(assets.rawSub(fee));
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
        if (fee > 0 && s_feeRecipient != address(this)) {
            i_asset.safeTransfer(s_feeRecipient, fee);
        }

        uint256 assetsToTransfer = assets.rawSub(fee);

        // Withdraw assets from strategy
        s_strategy.withdraw(assetsToTransfer);

        // Complete the withdrawal process
        super._withdraw(by, to, owner, assetsToTransfer, shares);
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
