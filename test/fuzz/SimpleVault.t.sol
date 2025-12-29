// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

import {BaseTest} from "../BaseTest.t.sol";

/// @title SimpleVaultTest
/// @notice Comprehensive test suite for SimpleVault functionality
/// @dev Tests vault operations, fee calculations, and strategy integration using mainnet fork
/// @author megabyte0x.eth
contract SimpleVaultTest is BaseTest {
    using FixedPointMathLib for uint256;

    function testFuzz_feeOnRaw(uint256 amount, uint256 fbps) public view {
        fbps = bound(fbps, 0, 10000);
        amount = bound(amount, 0, USDC_TO_MINT);

        uint256 totalAmount = vault.feeOnRaw(amount, fbps);

        uint256 expectedAmount = amount.mulDivUp(fbps, BASIS_POINT_SCALE);

        assertEq(totalAmount, expectedAmount);
    }

    function testFuzz_feeOnTotal(uint256 amount, uint256 fbps) public view {
        fbps = bound(fbps, 0, 10000);
        amount = bound(amount, 0, USDC_TO_MINT);

        uint256 totalAmount = vault.feeOnTotal(amount, fbps);

        uint256 expectedAmount = amount.mulDivUp(fbps, fbps + BASIS_POINT_SCALE);

        assertEq(totalAmount, expectedAmount);
    }

    /// @notice Fuzz test for deposit functionality with various amounts
    /// @dev Tests deposit amounts from 1 USDC to 100M USDC
    /// @param depositAmount Random deposit amount to test (bounded)
    function testFuzz_deposit(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);

        vm.startPrank(user);
        ERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        uint256 fee = vault.feeOnTotal(depositAmount, vault.getEntryFee());

        uint256 expected_supply = depositAmount - fee;

        assertEq(expected_supply, vault.totalSupply());
    }

    /// @notice Fuzz test for withdrawal functionality with various amounts
    /// @dev Tests withdrawal amounts up to the maximum allowed for the user
    /// @param depositAmount Random deposit amount (bounded)
    /// @param withdrawAmount Random withdrawal amount (bounded by max withdraw)
    function testFuzz_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);

        _deposit(depositAmount);

        uint256 maxWithdraw = vault.maxWithdraw(user);

        //! TODO: Remove debug console log before production
        console2.log("Max withdraw: ", maxWithdraw);

        withdrawAmount = bound(withdrawAmount, 1, maxWithdraw);

        uint256 balanceBeforeWithdraw = ERC20(networkConfig.usdc).balanceOf(user);

        _withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = ERC20(networkConfig.usdc).balanceOf(user);

        uint256 changeInBalance = balanceAfterWithdraw.rawSub(balanceBeforeWithdraw);

        uint256 expectedChangeInBalance =
            withdrawAmount.rawSub(withdrawAmount.mulDivUp(vault.getExitFee(), BASIS_POINT_SCALE));

        assertEq(changeInBalance, expectedChangeInBalance);
    }

    /// @notice Fuzz test for withdrawals when vault has sufficient unallocated funds
    /// @dev Tests scenario where withdrawal doesn't require asset reallocation from protocols
    /// @param depositAmount Random deposit amount (bounded)
    /// @param withdrawAmount Random withdrawal amount (bounded by unallocated funds)
    function testFuzz_withdraw_WhenUnallocatedFundsAreGreaterThanWithdrawAmount(
        uint256 depositAmount,
        uint256 withdrawAmount
    ) public {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);

        _deposit(depositAmount);

        uint256 unallocatedAmount = ERC20(networkConfig.usdc).balanceOf(address(vault));

        uint256 maxWithdraw = unallocatedAmount;

        //! TODO: Remove debug console log before production
        console2.log("Max withdraw: ", maxWithdraw);

        withdrawAmount = bound(withdrawAmount, 1, maxWithdraw);

        uint256 balanceBeforeWithdraw = ERC20(networkConfig.usdc).balanceOf(user);

        _withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = ERC20(networkConfig.usdc).balanceOf(user);

        uint256 changeInBalance = balanceAfterWithdraw.rawSub(balanceBeforeWithdraw);

        uint256 expectedChangeInBalance =
            withdrawAmount.rawSub(withdrawAmount.mulDivUp(vault.getExitFee(), BASIS_POINT_SCALE));

        assertEq(changeInBalance, expectedChangeInBalance);
    }

    /// @notice Fuzz test for total assets calculation with various deposit amounts
    /// @dev Ensures totalAssets calculation is correct across different vault sizes
    /// @param depositAmount Random deposit amount to test (bounded)
    function testFuzz_totalSupply(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);

        _deposit(depositAmount);

        uint256 totalAssets = vault.totalAssets();

        uint256 assetsInVault = ERC20(networkConfig.usdc).balanceOf(address(vault));
        uint256 assetsInMarkets = strategy.getTotalBalanceInMarkets();

        uint256 expectedAssets = assetsInVault + assetsInMarkets;

        assertEq(totalAssets, expectedAssets);
    }

    function testFuzz_previewDeposit_validAmounts(uint256 amount) public view {
        amount = bound(amount, 1e6, 1e12 * 1e6); // Between 1 USDC and 1T USDC

        uint256 shares = vault.previewDeposit(amount);

        // Shares should always be less than or equal to amount (due to fees)
        assertTrue(shares <= amount);
        assertTrue(shares > 0);

        // Verify fee calculation is correct
        uint256 expectedFee = vault.feeOnTotal(amount, vault.getEntryFee());
        uint256 assetsAfterFee = amount - expectedFee;
        uint256 expectedSharesAfterFee = assetsAfterFee;

        // In empty vault, shares should equal assets after fee
        if (vault.totalSupply() == 0) {
            assertEq(shares, expectedSharesAfterFee);
        }
    }

    /// @notice Fuzz test for previewMint functionality
    /// @dev Tests minting various amounts of shares and verifying asset calculations
    /// @param sharesToMint Random amount of shares to mint (bounded)
    function testFuzz_previewMint_validAmounts(uint256 sharesToMint) public view {
        sharesToMint = bound(sharesToMint, 1, 1e12 * 1e6); // Between 1 wei and 1T shares

        uint256 assetsNeeded = vault.previewMint(sharesToMint);

        // Assets needed should always be greater than or equal to shares (due to entry fees)
        assertTrue(assetsNeeded >= sharesToMint);
        assertTrue(assetsNeeded > 0);

        // Verify fee calculation is correct for empty vault
        if (vault.totalSupply() == 0) {
            uint256 expectedFee = vault.feeOnRaw(sharesToMint, vault.getEntryFee());
            uint256 expectedAssets = sharesToMint + expectedFee;
            assertEq(assetsNeeded, expectedAssets);
        }
    }

    /// @notice Fuzz test for previewMint with existing vault deposits
    /// @dev Tests minting when vault already has deposits and assets
    /// @param initialDeposit Initial deposit amount (bounded)
    /// @param sharesToMint Amount of shares to mint (bounded)
    function testFuzz_previewMint_nonEmptyVault(uint256 initialDeposit, uint256 sharesToMint) public {
        initialDeposit = bound(initialDeposit, 1e6, USDC_TO_MINT); // 1 USDC to 100M USDC
        sharesToMint = bound(sharesToMint, 1, 1e9 * 1e6); // 1 wei to 1B shares

        _deposit(initialDeposit);

        uint256 assetsNeeded = vault.previewMint(sharesToMint);

        // Assets needed should be greater than shares due to fees
        assertTrue(assetsNeeded >= sharesToMint);
        assertTrue(assetsNeeded > 0);

        // Verify the calculation makes sense with current exchange rate
        uint256 baseAssetsNeeded = sharesToMint.fullMulDivUp(vault.totalAssets() + 1, vault.totalSupply() + 1);
        uint256 expectedFee = vault.feeOnRaw(baseAssetsNeeded, vault.getEntryFee());
        uint256 expectedAssets = baseAssetsNeeded + expectedFee;

        assertEq(assetsNeeded, expectedAssets);
    }

    /// @notice Fuzz test for previewWithdraw functionality
    /// @dev Tests withdrawing various amounts and verifying share calculations
    /// @param depositAmount Initial deposit amount (bounded)
    /// @param withdrawAmount Amount to withdraw (bounded by max withdraw)
    function testFuzz_previewWithdraw_validAmounts(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);

        _deposit(depositAmount);

        uint256 maxWithdrawAmount = vault.maxWithdraw(user);
        withdrawAmount = bound(withdrawAmount, 1, maxWithdrawAmount);

        uint256 sharesBurned = vault.previewWithdraw(withdrawAmount);

        // Shares burned should be reasonable
        assertTrue(sharesBurned > 0);
        assertTrue(sharesBurned <= vault.balanceOf(user));

        // Verify fee calculation
        uint256 fee = vault.feeOnRaw(withdrawAmount, vault.getExitFee());
        uint256 assetsAfterFee = withdrawAmount + fee;
        uint256 expectedShares = assetsAfterFee.fullMulDivUp(vault.totalSupply(), vault.totalAssets());

        assertEq(sharesBurned, expectedShares);
    }

    /// @notice Fuzz test for previewWithdraw with different fee scenarios
    /// @dev Tests withdraw preview with various exit fee configurations
    /// @param depositAmount Initial deposit amount (bounded)
    /// @param withdrawAmount Amount to withdraw (bounded)
    /// @param exitFee Exit fee in basis points (bounded)
    function testFuzz_previewWithdraw_variableFees(uint256 depositAmount, uint256 withdrawAmount, uint256 exitFee)
        public
    {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);
        exitFee = bound(exitFee, 0, 1000); // 0% to 10% exit fee

        vault.setExitFee(exitFee);
        _deposit(depositAmount);

        uint256 maxWithdrawAmount = vault.maxWithdraw(user);
        withdrawAmount = bound(withdrawAmount, 1, maxWithdrawAmount);

        uint256 sharesBurned = vault.previewWithdraw(withdrawAmount);

        // Shares burned should be reasonable
        assertTrue(sharesBurned > 0);
        assertTrue(sharesBurned <= vault.balanceOf(user));

        // Higher exit fees should require more shares to be burned for same withdrawal
        if (exitFee > 0) {
            vault.setExitFee(0);
            uint256 sharesWithoutFee = vault.previewWithdraw(withdrawAmount);
            vault.setExitFee(exitFee); // Reset for consistency
            assertTrue(sharesBurned >= sharesWithoutFee);
        }
    }

    /// @notice Fuzz test for previewRedeem functionality
    /// @dev Tests redeeming various amounts of shares and verifying asset calculations
    /// @param depositAmount Initial deposit amount (bounded)
    /// @param sharesToRedeem Amount of shares to redeem (bounded by user balance)
    function testFuzz_previewRedeem_validAmounts(uint256 depositAmount, uint256 sharesToRedeem) public {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);

        _deposit(depositAmount);

        uint256 maxSharesThatCanBeRedeem = vault.maxRedeem(user);
        sharesToRedeem = bound(sharesToRedeem, 1e5, maxSharesThatCanBeRedeem);
        console2.log("Shares to redeem: ", sharesToRedeem);

        uint256 assetsReceived = vault.previewRedeem(sharesToRedeem);

        console2.log("Assets Received: ", assetsReceived);

        // Assets received should be reasonable
        assertTrue(assetsReceived > 0);
        assertTrue(assetsReceived <= vault.totalAssets());

        // Verify calculation with fees
        uint256 baseAssets = sharesToRedeem.fullMulDiv(vault.totalAssets(), vault.totalSupply());
        uint256 expectedFee = vault.feeOnTotal(baseAssets, vault.getExitFee());
        uint256 expectedAssets = baseAssets - expectedFee;

        assertEq(assetsReceived, expectedAssets);
    }

    /// @notice Fuzz test for previewRedeem with different fee scenarios
    /// @dev Tests redeem preview with various exit fee configurations
    /// @param depositAmount Initial deposit amount (bounded)
    /// @param sharesToRedeem Amount of shares to redeem (bounded)
    /// @param exitFee Exit fee in basis points (bounded)
    function testFuzz_previewRedeem_variableFees(uint256 depositAmount, uint256 sharesToRedeem, uint256 exitFee)
        public
    {
        depositAmount = bound(depositAmount, 1e6, USDC_TO_MINT);
        exitFee = bound(exitFee, 0, 1000); // 0% to 10% exit fee

        console2.log("Exit fee: ", exitFee);
        console2.log("Deposit amount: ", depositAmount);

        vault.setExitFee(exitFee);
        _deposit(depositAmount);

        uint256 maxSharesThatCanBeRedeem = vault.maxRedeem(user);
        sharesToRedeem = bound(sharesToRedeem, 1e5, maxSharesThatCanBeRedeem);

        console2.log("shares to redeem: ", sharesToRedeem);

        uint256 assetsReceived = vault.previewRedeem(sharesToRedeem);

        // Assets received should be reasonable
        assertTrue(assetsReceived > 0);

        // With zero exit fee, should get base asset value
        if (exitFee == 0) {
            uint256 baseAssets = sharesToRedeem.fullMulDiv(vault.totalAssets(), vault.totalSupply());
            assertEq(assetsReceived, baseAssets);
        } else {
            // With exit fee, should less more assets (fee included)
            uint256 baseAssets = sharesToRedeem.fullMulDiv(vault.totalAssets(), vault.totalSupply());
            assertTrue(assetsReceived < baseAssets);
        }
    }

    /// @notice Fuzz test for preview function consistency
    /// @dev Verifies that preview functions return consistent results with actual operations
    /// @param depositAmount Amount to deposit for setup (bounded)
    /// @param operationAmount Amount for the operation (bounded)
    function testFuzz_previewFunctions_consistency(uint256 depositAmount, uint256 operationAmount) public {
        depositAmount = bound(depositAmount, 1e6, 10_000_000e6);

        _deposit(depositAmount);

        // Test previewWithdraw and previewRedeem consistency
        uint256 maxWithdraw = vault.maxWithdraw(user);
        uint256 userShares = vault.balanceOf(user);

        operationAmount = bound(operationAmount, 1, maxWithdraw);

        // Preview withdraw for amount should be consistent
        uint256 sharesForWithdraw = vault.previewWithdraw(operationAmount);

        // Preview redeem for those shares should return approximately the same amount
        // (allowing for small rounding differences due to fees)
        if (sharesForWithdraw <= userShares && sharesForWithdraw > 0) {
            uint256 assetsFromRedeem = vault.previewRedeem(sharesForWithdraw);

            // The difference should be small due to fee calculations
            uint256 difference = assetsFromRedeem > operationAmount
                ? assetsFromRedeem - operationAmount
                : operationAmount - assetsFromRedeem;

            // Allow for small rounding differences (less than 1% of operation amount)
            assertTrue(difference <= operationAmount / 100);
        }
    }

    /// @notice Internal helper function to perform deposit operations
    /// @dev Handles approval and deposit in a single transaction
    /// @param depositAmount Amount of USDC to deposit
    function _deposit(uint256 depositAmount) internal {
        vm.startPrank(user);
        ERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
    }

    /// @notice Internal helper function to perform withdrawal operations
    /// @dev Withdraws specified amount to user's address
    /// @param withdrawAmount Amount of assets to withdraw
    function _withdraw(uint256 withdrawAmount) internal {
        vm.prank(user);
        vault.withdraw(withdrawAmount, user, user);
    }
}
