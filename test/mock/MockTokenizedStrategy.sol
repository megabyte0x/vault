// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {SimpleTokenizedStrategy} from "../../src/TokenizedStrategy/SimpleTokenizedStrategy.sol";
import {MockYieldSource} from "./MockYieldSource.sol";

contract MockTokenizedStrategy is SimpleTokenizedStrategy {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    constructor(address _yieldSource, address _vault) SimpleTokenizedStrategy(_yieldSource, _vault) {}

    function name() public pure override returns (string memory) {
        return "mockTokenizedStrategy";
    }

    function symbol() public pure override returns (string memory) {
        return "mockTS";
    }

    function totalAssets() public view override returns (uint256 assets) {
        assets = _getBalanceInAave();
    }

    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        super._deposit(by, to, assets, shares);

        // Supply to Aave
        asset().safeApprove(i_yieldSource, assets);
        MockYieldSource(i_yieldSource).supply(asset(), assets);
    }

    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        super._withdraw(by, to, owner, assets, shares);

        MockYieldSource(i_yieldSource).withdraw(asset(), assets);
    }

    /// @notice Gets the balance of assets deposited in Aave
    /// @dev Queries the aToken balance which represents deposits in Aave
    /// @return balance The amount of assets deposited in Aave
    function _getBalanceInAave() internal view returns (uint256 balance) {
        balance = MockYieldSource(i_yieldSource).balanceOf(asset(), address(this));
    }
}
