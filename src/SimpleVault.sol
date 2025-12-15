// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {Errors} from "./lib/Errors.sol";
import {ISimpleStrategy} from "./interfaces/ISimpleStrategy.sol";

contract SimpleVault is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    event SimpleVault__EntryFeeUpdated(uint256 newEntryFee);
    event SimpleVault__ExitFeeUpdated(uint256 newExitFee);
    event SimpleVault__FeeRecipientUpdated(address newFeeRecipient);
    event SimpleVault__StrategyUpdated(address newStrategy);

    address internal immutable i_asset;

    uint256 private constant BASIS_POINT_SCALE = 1e4;
    /// @dev As per USDC decimals (6)
    uint256 private constant MINIMUM_ASSET_REQUIRED = 1e6;

    /// @dev Fee in BPS.
    uint256 private s_entryFee;
    uint256 private s_exitFee;

    /// @notice Fee Recipient.
    address private s_feeRecipient;

    ISimpleStrategy private s_strategy;

    constructor(address asset_) {
        i_asset = asset_;
    }

    /*
       _____      _                        _   _____                 _   _
      | ____|_  _| |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      |  _| \ \/ / __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      | |___ >  <| ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_____/_/\_\\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    function setEntryFee(uint256 newEntryFee) external {
        s_entryFee = newEntryFee;

        emit SimpleVault__EntryFeeUpdated(newEntryFee);
    }

    function setExitFee(uint256 newExitFee) external {
        s_exitFee = newExitFee;

        emit SimpleVault__ExitFeeUpdated(newExitFee);
    }

    function setFeeRecipient(address newFeeRecipient) external {
        if (newFeeRecipient == address(0)) revert Errors.ZeroAddress();

        s_feeRecipient = newFeeRecipient;

        emit SimpleVault__FeeRecipientUpdated(newFeeRecipient);
    }

    function setStrategy(address newStrategy) external {
        if (newStrategy == address(0)) revert Errors.ZeroAddress();

        if (address(s_strategy) != address(0)) {
            s_strategy.withdrawFunds();
        }

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

    /// @inheritdoc ERC20
    function name() public pure override returns (string memory) {
        return "Simple Vault";
    }

    /// @inheritdoc ERC20
    function symbol() public pure override returns (string memory) {
        return "SV";
    }

    /// @inheritdoc ERC4626
    function asset() public view override returns (address) {
        return i_asset;
    }

    /// @inheritdoc ERC4626
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        if (assets < MINIMUM_ASSET_REQUIRED) revert Errors.MinimumAssetRequired();
        uint256 fee = _feeOnTotal(assets, getEntryFee());
        return super.previewDeposit(assets.rawSub(fee));
    }

    /// @inheritdoc ERC4626
    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewMint(shares);
        return (assets.rawAdd(_feeOnRaw(assets, getEntryFee())));
    }

    /// @inheritdoc ERC4626
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        uint256 fee = _feeOnTotal(assets, getExitFee());
        return super.previewWithdraw(assets.rawSub(fee));
    }

    /// @inheritdoc ERC4626
    function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewRedeem(shares);
        return (assets.rawAdd(_feeOnRaw(assets, getExitFee())));
    }

    /// @inheritdoc ERC4626
    function totalAssets() public view override returns (uint256 assets) {
        assets = s_strategy.totalAssets();
    }

    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }

    function getExitFee() public view returns (uint256) {
        return s_exitFee;
    }

    /*
       ___       _                        _   _____                 _   _
      |_ _|_ __ | |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
       | || '_ \| __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
       | || | | | ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |___|_| |_|\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @inheritdoc ERC4626
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(i_asset).decimals();
    }

    /// @inheritdoc ERC4626
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        super._deposit(by, to, assets, shares);

        uint256 fee = _feeOnTotal(assets, getEntryFee());

        if (fee > 0 && s_feeRecipient != address(this)) {
            i_asset.safeTransfer(s_feeRecipient, fee);
        }

        s_strategy.supply(assets.rawSub(fee));
    }

    /// @inheritdoc ERC4626
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        uint256 fee = _feeOnRaw(assets, getExitFee());

        if (fee > 0 && s_feeRecipient != address(this)) {
            i_asset.safeTransfer(s_feeRecipient, fee);
        }

        s_strategy.withdraw(assets.rawSub(fee));

        console2.log("total Balance after deallocation: ", s_strategy.totalAssets());

        super._withdraw(by, to, owner, assets.rawSub(fee), shares);
    }

    /// @dev Calculates the fees that should be added to an amount `assets` that does not already include fees.
    /// Used in {ERC4626-mint} and {ERC4626-withdraw} operations.
    function _feeOnRaw(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, BASIS_POINT_SCALE);
    }

    /// @dev Calculates the fee part of an amount `assets` that already includes fees.
    /// Used in {ERC4626-deposit} and {ERC4626-redeem} operations.
    function _feeOnTotal(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, BASIS_POINT_SCALE);
    }
}
