// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SimpleTokenizedStrategy, ERC20} from "./SimpleTokenizedStrategy.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {IPool as IAave} from "../interfaces/IAavePool.sol";

/// @title AaveTokenizedStrategy
/// @notice Tokenized strategy that deposits assets into Aave lending pool for yield generation
/// @dev Extends SimpleTokenizedStrategy with Aave-specific implementation for deposits and withdrawals
/// @author megabyte0x.eth
contract AaveTokenizedStrategy is SimpleTokenizedStrategy {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @notice Referral code for Aave deposits (0 = no referral)
    uint16 internal constant REFERRAL_CODE = 0;

    /// @notice Initializes the Aave tokenized strategy
    /// @param _yieldSource The address of the Aave lending pool
    /// @param _vault The address of the vault that will manage this strategy
    constructor(address _yieldSource, address _vault) SimpleTokenizedStrategy(_yieldSource, _vault) {}

    /// @notice Returns the name of the strategy token
    /// @inheritdoc ERC20
    /// @return The strategy token name
    function name() public pure override returns (string memory) {
        return "aaveTokenizedStrategy";
    }

    /// @notice Returns the symbol of the strategy token
    /// @inheritdoc ERC20
    /// @return The strategy token symbol
    function symbol() public pure override returns (string memory) {
        return "aaveTS";
    }

    /// @notice Returns the total amount of assets deployed in Aave
    /// @inheritdoc SimpleTokenizedStrategy
    /// @dev Queries aToken balance to get current deposited amount
    /// @return assets The total amount of underlying assets in Aave
    function totalAssets() public view override returns (uint256 assets) {
        assets = _getBalanceInAave();
    }

    /// @notice Hook called after deposits to deploy assets to Aave
    /// @dev Approves and supplies assets to Aave lending pool
    /// @param assets The amount of assets being deposited
    /// @param shares The amount of shares being minted (unused in this implementation)
    function _afterDeposit(uint256 assets, uint256 shares) internal override {
        // Approve and supply assets to Aave
        asset().safeApprove(i_yieldSource, assets);
        IAave(i_yieldSource).supply(asset(), assets, address(this), REFERRAL_CODE);
    }

    /// @notice Hook called before withdrawals to retrieve assets from Aave
    /// @dev Withdraws assets from Aave lending pool back to strategy
    /// @param assets The amount of assets being withdrawn
    /// @param shares The amount of shares being burned (unused in this implementation)
    function _beforeWithdraw(uint256 assets, uint256 shares) internal override {
        IAave(i_yieldSource).withdraw(asset(), assets, address(this));
    }

    /// @notice Gets the balance of assets deposited in Aave
    /// @dev Queries the aToken balance which represents deposits in Aave
    /// @return balance The amount of assets deposited in Aave
    function _getBalanceInAave() internal view returns (uint256 balance) {
        address aToken = IAave(i_yieldSource).getReserveAToken(asset());
        balance = ERC20(aToken).balanceOf(address(this));
    }
}
