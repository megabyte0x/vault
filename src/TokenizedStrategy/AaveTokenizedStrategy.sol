// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SimpleTokenizedStrategy, ERC20} from "./SimpleTokenizedStrategy.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {IPool as IAave} from "../interfaces/IAavePool.sol";

contract AaveTokenizedStrategy is SimpleTokenizedStrategy {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @notice Referral code for Aave deposits (0 = no referral)
    uint16 internal constant REFERRAL_CODE = 0;

    constructor(address _yieldSource, address _vault) SimpleTokenizedStrategy(_yieldSource, _vault) {}

    function name() public pure override returns (string memory) {
        return "aaveTokenizedStrategy";
    }

    function symbol() public pure override returns (string memory) {
        return "aaveTS";
    }

    function totalAssets() public view override returns (uint256 assets) {
        assets = _getBalanceInAave();
    }

    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        super._deposit(by, to, assets, shares);

        // Supply to Aave
        asset().safeApprove(i_yieldSource, assets);
        IAave(i_yieldSource).supply(asset(), assets, address(this), REFERRAL_CODE);
    }

    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        super._withdraw(by, to, owner, assets, shares);

        IAave(i_yieldSource).withdraw(asset(), assets, i_vault);
    }

    /// @notice Gets the balance of assets deposited in Aave
    /// @dev Queries the aToken balance which represents deposits in Aave
    /// @return balance The amount of assets deposited in Aave
    function _getBalanceInAave() internal view returns (uint256 balance) {
        address aToken = IAave(i_yieldSource).getReserveAToken(asset());
        balance = ERC20(aToken).balanceOf(address(this));
    }
}
