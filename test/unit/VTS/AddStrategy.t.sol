// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "../../../src/lib/Errors.sol";
import {MockTokenizedStrategy, BaseTestForVTS} from "../../BaseTestForVTS.t.sol";

/**
 * @title AddStrategy Test Suite for SimpleVaultWithTokenizedStrategy
 * @notice Tests for adding strategies to the vault
 * @dev Tests various scenarios including first strategy, multiple strategies, and error conditions
 */
contract AddStrategy__VTS is BaseTestForVTS {
    using FixedPointMathLib for uint256;

    /**
     * @notice Test adding first strategy to an empty vault
     * @dev Verifies strategy index and total strategies count are correctly set
     */
    function test_addStrategy_FirstStrategyWithEmptyVault() public {
        uint256 cap = 90_00; // 90%

        _addStrategy(cap);

        uint256 currentStrategyIndex = vault.getStrategyIndex(address(strategy));
        uint256 expectedStrategyIndex = 0;

        assertEq(currentStrategyIndex, expectedStrategyIndex);

        uint256 currentTotalStrategies = vault.getTotalStrategies();
        uint256 expectedTotalStrategies = 1;

        assertEq(currentTotalStrategies, expectedTotalStrategies);
    }

    /**
     * @notice Test adding first strategy after deposits have been made
     * @dev Verifies funds are correctly allocated to the strategy based on cap percentage
     */
    function test_addStrategy_FirstStrategy() public {
        uint256 cap = 90_00; // 90%

        _deposit(DEPOSIT_AMOUNT);

        uint256 feeAmount = DEPOSIT_AMOUNT.mulDivUp(vault.getEntryFee(), vault.getEntryFee() + BASIS_POINT_SCALE);
        uint256 finalDepositAmount = DEPOSIT_AMOUNT.rawSub(feeAmount);

        _addStrategy(cap);

        uint256 assetsInStrategy = vault.getAssetInStrategy(address(strategy));

        uint256 expectedAssetsInStrategy = finalDepositAmount.mulDiv(cap, BASIS_POINT_SCALE);

        assertEq(assetsInStrategy, expectedAssetsInStrategy);
    }

    /**
     * @notice Test adding a second strategy to vault with existing strategy
     * @dev Verifies multiple strategies can coexist with proper caps and total assets tracking
     */
    function test_addStrategy_SecondStrategy() public {
        uint256 firstStrategyCap = 85_00;
        uint256 secondStrategyCap = 12_00;

        uint256 feeAmount = DEPOSIT_AMOUNT.mulDivUp(vault.getEntryFee(), vault.getEntryFee() + BASIS_POINT_SCALE);
        uint256 finalDepositAmount = DEPOSIT_AMOUNT.rawSub(feeAmount);

        _deposit(DEPOSIT_AMOUNT);
        _addStrategy(firstStrategyCap);

        MockTokenizedStrategy strategy2 = new MockTokenizedStrategy(address(yieldSource), address(vault));

        vm.prank(curator);
        vault.addStrategy(address(strategy2), secondStrategyCap);

        uint256 assetsInStrategy1 = vault.getAssetInStrategy(address(strategy));
        uint256 assetsInStrategy2 = vault.getAssetInStrategy(address(strategy2));

        uint256 expectedAssetsInStrategy1 = finalDepositAmount.mulDiv(firstStrategyCap, BASIS_POINT_SCALE);
        uint256 expectedAssetsInStrategy2 = finalDepositAmount.mulDiv(secondStrategyCap, BASIS_POINT_SCALE);

        assertEq(assetsInStrategy1, expectedAssetsInStrategy1);
        assertEq(assetsInStrategy2, expectedAssetsInStrategy2);

        uint256 totalAssets = vault.totalAssets();
        uint256 expectedTotalAssets = finalDepositAmount;

        assertEq(totalAssets, expectedTotalAssets);
    }

    /**
     * @notice Test that adding strategy with zero address reverts
     * @dev Expects revert with ZeroAddress error
     */
    function test_addStrategy_StrategyWithZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(curator);
        vault.addStrategy(address(0), 0);
    }

    /**
     * @notice Test that adding duplicate strategy reverts
     * @dev Expects revert with StrategyAlreadyAdded error when adding same strategy twice
     */
    function test_addStrategy_StrategyAlreadyAdded() public {
        uint256 cap = 90_00; // 90%

        vm.startPrank(curator);
        vault.addStrategy(address(strategy), cap);
        vm.expectRevert(Errors.StrategyAlreadyAdded.selector);
        vault.addStrategy(address(strategy), BASIS_POINT_SCALE.rawSub(cap));
        vm.stopPrank();
    }

    /**
     * @notice Test that adding strategy exceeding total cap limit reverts
     * @dev Expects revert when strategy cap plus minimum idle assets exceeds 100%
     */
    function test_addStrategy_StrategyExceedingTotalCap() public {
        uint256 cap = 96_00; // 96%

        vm.prank(curator);
        vm.expectRevert(Errors.TotalCapExceeded.selector);
        vault.addStrategy(address(strategy), cap);
    }

    /**
     * @notice Test that adding strategy with zero cap reverts
     * @dev Expects revert with ZeroAmount error
     */
    function test_addStrategy_StrategyWithZeroCap() public {
        vm.prank(curator);

        vm.expectRevert(Errors.ZeroAmount.selector);
        vault.addStrategy(address(strategy), 0);
    }

    // ==========================================================================

    /**
     * @notice Internal helper function to perform deposit operations
     * @dev Handles approval and deposit in a single transaction
     * @param depositAmount Amount of USDC to deposit
     */
    function _deposit(uint256 depositAmount) internal {
        vm.startPrank(user);
        ERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
    }

    /**
     * @notice Internal helper function to perform withdrawal operations
     * @dev Withdraws specified amount to user's address
     * @param withdrawAmount Amount of assets to withdraw
     */
    function _withdraw(uint256 withdrawAmount) internal {
        vm.prank(user);
        vault.withdraw(withdrawAmount, user, user);
    }

    /**
     * @notice Internal helper function to add strategy as curator
     * @dev Pranks as curator to add strategy with specified cap
     * @param cap Cap percentage in basis points (10000 = 100%)
     */
    function _addStrategy(uint256 cap) internal {
        vm.prank(curator);
        vault.addStrategy(address(strategy), cap);
    }
}
