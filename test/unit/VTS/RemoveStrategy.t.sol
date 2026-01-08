// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "../../../src/lib/Errors.sol";
import {BaseTestForVTS} from "../../BaseTestForVTS.t.sol";

/**
 * @title RemoveStrategy Test Suite for SimpleVaultWithTokenizedStrategy
 * @notice Tests for removing strategies from the vault
 * @dev Tests strategy removal scenarios and error conditions
 */
contract RemoveStrategy__VTS is BaseTestForVTS {
    using FixedPointMathLib for uint256;

    /**
     * @notice Test removing a strategy when one strategy exists
     * @dev Verifies that funds are properly withdrawn from strategy back to vault
     */
    function test_removeStrategy_WhenOneStrategyExists() public {
        uint256 cap = 90_00;

        _deposit(DEPOSIT_AMOUNT);

        uint256 feeAmount = DEPOSIT_AMOUNT.mulDivUp(vault.getEntryFee(), vault.getEntryFee() + BASIS_POINT_SCALE);
        uint256 finalDepositAmount = DEPOSIT_AMOUNT.rawSub(feeAmount);

        _addStrategy(cap);

        vm.prank(curator);
        vault.removeStrategy(address(strategy));

        uint256 totalAssetsInVault = vault.totalAssets();
        uint256 balanceInVault = ERC20(networkConfig.usdc).balanceOf(address(vault));

        assertEq(totalAssetsInVault, balanceInVault);
        assertEq(balanceInVault, finalDepositAmount);
    }

    /**
     * @notice Test that removing non-existent strategy reverts
     * @dev Expects revert with StrategyNotFound error
     */
    function test_Revert_RemoveStrategyCalledWhenStrategyDontExist() public {
        vm.prank(curator);
        vm.expectRevert(Errors.StrategyNotFound.selector);
        vault.removeStrategy(address(strategy));
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
