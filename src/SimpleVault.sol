// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {Errors} from "./lib/Errors.sol";

contract SimpleVault is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    event SimpleVault__EntryFeeUpdated();
    event SimpleVault__ExitFeeUpdated();
    event SimpleVault__FeeReceipientUpdated();

    address internal immutable i_asset;

    uint256 private constant BASIS_POINT_SCALE = 1e4;

    /// @dev Fee in BPS.
    uint256 private s_entryFee;
    uint256 private s_exitFee;

    /// @notice Fee Receipient.
    address private s_feeReceipient;

    constructor(address asset_) {
        i_asset = asset_;
    }

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
        uint256 fee = _feeOnTotal(assets, s_entryFee);
        return super.previewDeposit(assets.rawSub(fee));
    }

    /// @inheritdoc ERC4626
    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewMint(shares);
        return (assets.rawAdd(_feeOnRaw(assets, s_entryFee)));
    }

    /// @inheritdoc ERC4626
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        uint256 fee = _feeOnTotal(assets, s_exitFee);
        return super.previewWithdraw(assets.rawSub(fee));
    }

    /// @inheritdoc ERC4626
    function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewRedeem(shares);
        return (assets.rawAdd(_feeOnRaw(assets, s_exitFee)));
    }

    function setEntryFee(uint256 newEntryFee) external {
        s_entryFee = newEntryFee;
        emit SimpleVault__EntryFeeUpdated();
    }

    function setExitFee(uint256 newExitFee) external {
        s_exitFee = newExitFee;
        emit SimpleVault__ExitFeeUpdated();
    }

    function setFeeReceipient(address newFeeReceipient) external {
        if (newFeeReceipient == address(0)) revert Errors.ZeroAddress();
        s_feeReceipient = newFeeReceipient;
        emit SimpleVault__FeeReceipientUpdated();
    }

    function getEntryFee() external view returns (uint256) {
        return s_entryFee;
    }

    function getExitFee() external view returns (uint256) {
        return s_exitFee;
    }

    /// @inheritdoc ERC4626
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(i_asset).decimals();
    }

    /// @inheritdoc ERC4626
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        uint256 fee = _feeOnTotal(assets, s_entryFee);

        super._deposit(by, to, assets, shares);

        if (fee > 0 && s_feeReceipient != address(this)) {
            i_asset.safeTransfer(s_feeReceipient, fee);
        }
    }

    /// @inheritdoc ERC4626
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        uint256 fee = _feeOnRaw(assets, s_exitFee);

        super._withdraw(by, to, owner, assets, shares);

        if (fee > 0 && s_feeReceipient != address(this)) {
            i_asset.safeTransfer(s_feeReceipient, fee);
        }
    }

    // === Fee operations ===
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
