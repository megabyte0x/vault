// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {ERC20, ERC4626, SimpleTokenizedStrategy} from "../../src/TokenizedStrategy/SimpleTokenizedStrategy.sol";
import {MockYieldSource} from "./MockYieldSource.sol";

/// @title MockTokenizedStrategy
/// @notice Mock implementation of a tokenized strategy for testing purposes
/// @dev Uses MockYieldSource instead of real protocols like Aave for controlled testing environment
/// @author megabyte0x.eth
contract MockTokenizedStrategy is SimpleTokenizedStrategy {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @notice Initializes the mock strategy with a mock yield source
    /// @param _yieldSource The address of the MockYieldSource contract
    /// @param _vault The address of the vault that will manage this strategy
    constructor(address _yieldSource, address _vault) SimpleTokenizedStrategy(_yieldSource, _vault) {}

    /// @notice Returns the name of the mock strategy token
    /// @inheritdoc ERC20
    /// @return The mock strategy token name
    function name() public pure override returns (string memory) {
        return "mockTokenizedStrategy";
    }

    /// @notice Returns the symbol of the mock strategy token
    /// @inheritdoc ERC20
    /// @return The mock strategy token symbol
    function symbol() public pure override returns (string memory) {
        return "mockTS";
    }

    /// @notice Returns the total amount of assets deployed in the mock yield source
    /// @inheritdoc ERC4626
    /// @dev Queries mock balance instead of real protocol balance
    /// @return assets The total amount of underlying assets in the mock yield source
    function totalAssets() public view override returns (uint256 assets) {
        assets = _getBalanceInAave();
    }

    /// @notice Internal hook called after deposits to deploy assets to mock yield source
    /// @inheritdoc ERC4626
    /// @dev Approves and supplies assets to MockYieldSource for testing
    /// @param by The address initiating the deposit
    /// @param to The address receiving the shares
    /// @param assets The amount of assets being deposited
    /// @param shares The amount of shares being minted
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        super._deposit(by, to, assets, shares);

        // Supply assets to mock yield source
        asset().safeApprove(i_yieldSource, assets);
        MockYieldSource(i_yieldSource).supply(asset(), assets);
    }

    /// @notice Internal hook called before withdrawals to retrieve assets from mock yield source
    /// @inheritdoc ERC4626
    /// @dev Withdraws assets from MockYieldSource back to strategy for testing
    /// @param by The address initiating the withdrawal
    /// @param to The address receiving the assets
    /// @param owner The address owning the shares being burned
    /// @param assets The amount of assets being withdrawn
    /// @param shares The amount of shares being burned
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        super._withdraw(by, to, owner, assets, shares);

        MockYieldSource(i_yieldSource).withdraw(asset(), assets);
    }

    /// @notice Gets the balance of assets deposited in the mock yield source
    /// @dev Queries the mock balance which simulates deposits in a real protocol
    /// @return balance The amount of assets deposited in the mock yield source
    function _getBalanceInAave() internal view returns (uint256 balance) {
        balance = MockYieldSource(i_yieldSource).balanceOf(asset(), address(this));
    }
}
