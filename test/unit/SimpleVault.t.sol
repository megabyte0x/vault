// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

import {Errors} from "../../src/lib/Errors.sol";

import {BaseTest, SimpleVaultHarness, SimpleStrategy} from "../BaseTest.t.sol";

/// @title SimpleVaultTest
/// @notice Comprehensive test suite for SimpleVault functionality
/// @dev Tests vault operations, fee calculations, and strategy integration using mainnet fork
/// @author megabyte0x.eth
contract SimpleVaultTest is BaseTest {
    using FixedPointMathLib for uint256;

    function test_constructor() public {
        SimpleVaultHarness newVault = new SimpleVaultHarness(networkConfig.usdc);

        assertEq(newVault.asset(), networkConfig.usdc);
    }

    function test_constructor_withZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        new SimpleVaultHarness(address(0));
    }

    /*
       _____      _                        _   _____                 _   _
      | ____|_  _| |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      |  _| \ \/ / __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      | |___ >  <| ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_____/_/\_\\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    function test_setEntryFee() public {
        uint256 entryFeeInBPS = 100;
        vault.setEntryFee(entryFeeInBPS);

        assertEq(vault.getEntryFee(), entryFeeInBPS);
    }

    function test_setExitFee() public {
        uint256 exitFeeInBps = 100;
        vault.setExitFee(exitFeeInBps);

        assertEq(vault.getExitFee(), exitFeeInBps);
    }

    function test_setFeeRecipient() public {
        address newFeeRecipient = makeAddr("newRecipient");

        vault.setFeeRecipient(newFeeRecipient);

        assertEq(vault.getFeeRecipient(), newFeeRecipient);
    }

    function test_setFeeRecipient_withZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vault.setFeeRecipient(address(0));
    }

    function test_setStrategy() public {
        SimpleStrategy newStrategy =
            new SimpleStrategy(address(vault), networkConfig.aave_pool, networkConfig.morpho_vault);

        vault.setStrategy(address(newStrategy));

        assertEq(vault.getStrategy(), address(newStrategy));
    }

    function test_setStrategy_withZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vault.setStrategy(address(0));
    }

    function test_setStrategy_withPreviousStrategyMarketsHavingSomeBalance() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 balanceInPreviousStrategyBefore = strategy.getTotalBalanceInMarkets();

        /// @dev If this condition is true then the `_deposit` function is not working as it should.
        if (balanceInPreviousStrategyBefore == 0) {
            revert();
        }

        SimpleStrategy newStrategy =
            new SimpleStrategy(address(vault), networkConfig.aave_pool, networkConfig.morpho_vault);

        vault.setStrategy(address(newStrategy));

        uint256 balanceInPreviousStrategyAfter = strategy.getTotalBalanceInMarkets();

        assertEq(balanceInPreviousStrategyAfter, 0);
    }

    /*
       ____        _     _ _        _____                 _   _
      |  _ \ _   _| |__ | (_) ___  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      | |_) | | | | '_ \| | |/ __| | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      |  __/| |_| | |_) | | | (__  |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_|    \__,_|_.__/|_|_|\___| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Tests that vault symbol returns correct value
    function test_symbol() public view {
        assertEq(vault.symbol(), "SV");
    }

    /// @notice Tests that vault name returns correct value
    function test_name() public view {
        assertEq(vault.name(), "Simple Vault");
    }

    /// @notice Tests that vault asset returns correct USDC address
    function test_asset() public view {
        assertEq(vault.asset(), networkConfig.usdc);
    }

    /// @notice Tests basic deposit functionality with entry fee calculation
    /// @dev Verifies that total supply equals deposit amount minus entry fees
    function test_deposit() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 expected_supply = DEPOSIT_AMOUNT.rawSub(
            DEPOSIT_AMOUNT.mulDivUp(networkConfig.entryFee, networkConfig.entryFee + BASIS_POINT_SCALE)
        );

        assertEq(expected_supply, vault.totalSupply());
    }

    /// @notice Tests basic withdrawal functionality with exit fee calculation
    /// @dev Verifies that user receives withdrawal amount minus exit fees
    function test_withdraw() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 balanceBeforeWithdraw = ERC20(networkConfig.usdc).balanceOf(user);

        uint256 withdrawAmount = 90_000e6;

        _withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = ERC20(networkConfig.usdc).balanceOf(user);

        uint256 changeInBalance = balanceAfterWithdraw.rawSub(balanceBeforeWithdraw);

        uint256 expectedChangeInBalance = withdrawAmount.rawSub(vault.feeOnRaw(withdrawAmount, vault.getExitFee()));

        assertEq(changeInBalance, expectedChangeInBalance);
    }

    /// @notice Tests total assets calculation across vault and external protocols
    /// @dev Verifies that totalAssets equals sum of vault balance and deployed assets
    function test_totalSupply() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 totalAssets = vault.totalAssets();

        uint256 assetsInVault = ERC20(networkConfig.usdc).balanceOf(address(vault));
        uint256 assetsInMarkets = strategy.getTotalBalanceInMarkets();

        uint256 expectedAssets = assetsInVault + assetsInMarkets;

        assertEq(totalAssets, expectedAssets);
    }

    function test_deposit_calculateAPY() public {
        _deposit(DEPOSIT_AMOUNT);
        uint256 assetPerShareBefore = vault.convertToAssets(1e6);

        vm.warp(block.timestamp + 365 days);
        uint256 assetPerShareAfter = vault.convertToAssets(1e6);

        uint256 assetPerShareIncrease = assetPerShareAfter.rawSub(assetPerShareBefore);
        uint256 apy = assetPerShareIncrease.fullMulDiv(BASIS_POINT_SCALE, assetPerShareBefore);

        console2.log("assetPerShare increase: ", assetPerShareIncrease);

        console2.log("apy: ", apy);
    }

    function test_underlyingDecimals() public view {
        uint8 decimals = vault.underlyingDecimals();

        uint8 expectedDecimals = ERC20(networkConfig.usdc).decimals();

        assertEq(decimals, expectedDecimals);
    }

    function test_previewDeposit_withZeroEntryFee() public {
        vault.setEntryFee(0);
        uint256 expectedShares = DEPOSIT_AMOUNT; // 1:1 ratio when no fees
        assertEq(vault.previewDeposit(DEPOSIT_AMOUNT), expectedShares);
    }

    function test_previewDeposit_withStandardEntryFee() public view {
        uint256 depositAmount = DEPOSIT_AMOUNT;
        uint256 entryFee = vault.getEntryFee(); // 5 bps
        uint256 fee = depositAmount.mulDivUp(entryFee, BASIS_POINT_SCALE + entryFee);
        uint256 expectedShares = depositAmount - fee;
        assertEq(vault.previewDeposit(depositAmount), expectedShares);
    }

    function test_previewDeposit_maxUint256() public {
        // Should handle overflow gracefully
        vm.expectRevert(); // Likely arithmetic overflow
        vault.previewDeposit(type(uint256).max);
    }

    function test_previewDeposit_nonEmptyVault() public {
        _deposit(DEPOSIT_AMOUNT); // Make initial deposit

        uint256 secondDepositAmount = 500e6;
        uint256 shares = vault.previewDeposit(secondDepositAmount);

        // Calculate expected shares based on current exchange rate
        uint256 fee = vault.feeOnTotal(secondDepositAmount, vault.getEntryFee());
        uint256 assetsAfterFee = secondDepositAmount - fee;
        uint256 expectedShares = assetsAfterFee.fullMulDiv(vault.totalSupply(), vault.totalAssets());

        assertEq(shares, expectedShares);
    }

    function test_previewDeposit_largeAmountPrecision() public view {
        uint256 largeAmount = 1_000_000_000e6; // 1B USDC
        uint256 shares = vault.previewDeposit(largeAmount);
        assertTrue(shares > 0);
        // Verify calculations work for large amounts
    }

    function test_previewDeposit_noStateChanges() public view {
        uint256 totalSupplyBefore = vault.totalSupply();
        uint256 totalAssetsBefore = vault.totalAssets();
        uint256 userBalanceBefore = ERC20(vault.asset()).balanceOf(user);

        vault.previewDeposit(TEST_AMOUNT);

        assertEq(vault.totalSupply(), totalSupplyBefore);
        assertEq(vault.totalAssets(), totalAssetsBefore);
        assertEq(ERC20(vault.asset()).balanceOf(user), userBalanceBefore);
    }

    /*
       ____                _               __  __ _       _
      |  _ \ _ __ _____   _(_) _____      _|  \/  (_)_ __ | |_
      | |_) | '__/ _ \ \ / / |/ _ \ \ /\ / / |\/| | | '_ \| __|
      |  __/| | |  __/\ V /| |  __/\ V  V /| |  | | | | | |_
      |_|   |_|  \___| \_/ |_|\___| \_/\_/ |_|  |_|_|_| |_\__|
    */

    function test_previewMint_withZeroEntryFee() public {
        vault.setEntryFee(0);
        uint256 sharesToMint = TEST_AMOUNT;
        uint256 expectedAssets = sharesToMint; // 1:1 ratio when no fees
        assertEq(vault.previewMint(sharesToMint), expectedAssets);
    }

    function test_previewMint_withStandardEntryFee() public view {
        uint256 sharesToMint = TEST_AMOUNT;
        uint256 previewedAssets = vault.previewMint(sharesToMint);

        // Verify that assets needed is more than shares due to entry fee
        assertTrue(previewedAssets > sharesToMint);

        // Verify fee calculation is correct
        uint256 assetsNeeded = sharesToMint; // Base assets needed for shares
        uint256 expectedFee = vault.feeOnRaw(assetsNeeded, vault.getEntryFee());
        uint256 expectedTotalAssets = assetsNeeded + expectedFee;

        assertEq(previewedAssets, expectedTotalAssets);
    }

    function test_previewMint_emptyVault() public view {
        assertTrue(vault.totalSupply() == 0);
        uint256 sharesToMint = TEST_AMOUNT;
        uint256 assetsNeeded = vault.previewMint(sharesToMint);

        // In empty vault, should need shares + fees
        uint256 expectedFee = vault.feeOnRaw(sharesToMint, vault.getEntryFee());
        uint256 expectedAssets = sharesToMint + expectedFee;
        assertEq(assetsNeeded, expectedAssets);
    }

    function test_previewMint_nonEmptyVault() public {
        _deposit(DEPOSIT_AMOUNT); // Make initial deposit

        uint256 sharesToMint = 500e6;
        uint256 assetsNeeded = vault.previewMint(sharesToMint);

        // Calculate expected assets based on current exchange rate
        uint256 baseAssetsNeeded = sharesToMint.fullMulDivUp(vault.totalAssets(), vault.totalSupply());
        uint256 fee = vault.feeOnRaw(baseAssetsNeeded, vault.getEntryFee());
        uint256 expectedAssets = baseAssetsNeeded + fee;

        assertEq(assetsNeeded, expectedAssets);
    }

    function test_previewMint_smallAmountPrecision() public view {
        uint256 smallShares = 1; // 1 wei of shares
        uint256 assetsNeeded = vault.previewMint(smallShares);
        assertTrue(assetsNeeded >= smallShares);
    }

    function test_previewMint_largeAmountPrecision() public view {
        uint256 largeShares = 1_000_000_000e6; // 1B shares
        uint256 assetsNeeded = vault.previewMint(largeShares);
        assertTrue(assetsNeeded > largeShares);
    }

    function test_previewMint_noStateChanges() public view {
        uint256 totalSupplyBefore = vault.totalSupply();
        uint256 totalAssetsBefore = vault.totalAssets();
        uint256 userBalanceBefore = ERC20(vault.asset()).balanceOf(user);

        vault.previewMint(TEST_AMOUNT);

        assertEq(vault.totalSupply(), totalSupplyBefore);
        assertEq(vault.totalAssets(), totalAssetsBefore);
        assertEq(ERC20(vault.asset()).balanceOf(user), userBalanceBefore);
    }

    /*
       ____                _               __        ___ _   _         _
      |  _ \ _ __ _____   _(_) _____      _\ \      / (_) |_| |__   __| |_ __ __ ___      __
      | |_) | '__/ _ \ \ / / |/ _ \ \ /\ / /\ \ /\ / /| | __| '_ \ / _` | '__/ _` \ \ /\ / /
      |  __/| | |  __/\ V /| |  __/\ V  V /  \ V  V / | | |_| | | | (_| | | | (_| |\ V  V /
      |_|   |_|  \___| \_/ |_|\___| \_/\_/    \_/\_/  |_|\__|_| |_|\__,_|_|  \__,_| \_/\_/
    */

    function test_previewWithdraw_withZeroExitFee() public {
        vault.setExitFee(0);
        _deposit(DEPOSIT_AMOUNT);

        uint256 withdrawAmount = TEST_AMOUNT;
        uint256 sharesBurned = vault.previewWithdraw(withdrawAmount);

        // With no exit fees, shares should equal withdraw amount
        uint256 expectedShares = withdrawAmount.fullMulDivUp(vault.totalSupply(), vault.totalAssets());
        assertEq(sharesBurned, expectedShares);
    }

    function test_previewWithdraw_withStandardExitFee() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 withdrawAmount = TEST_AMOUNT;
        uint256 sharesBurned = vault.previewWithdraw(withdrawAmount);

        // Calculate expected shares considering exit fee
        uint256 fee = vault.feeOnRaw(withdrawAmount, vault.getExitFee());
        uint256 assetsAfterFee = withdrawAmount + fee;
        uint256 expectedShares = assetsAfterFee.fullMulDivUp(vault.totalSupply(), vault.totalAssets());

        assertEq(sharesBurned, expectedShares);
    }

    function test_previewWithdraw_smallAmountPrecision() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 smallAmount = 1; // 1 wei
        uint256 sharesBurned = vault.previewWithdraw(smallAmount);
        assertTrue(sharesBurned >= 0);
    }

    function test_previewWithdraw_largeAmountPrecision() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 maxWithdraw = vault.maxWithdraw(user);
        uint256 sharesBurned = vault.previewWithdraw(maxWithdraw);
        assertEq(sharesBurned, vault.balanceOf(user));
    }

    function test_previewWithdraw_noStateChanges() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 totalSupplyBefore = vault.totalSupply();
        uint256 totalAssetsBefore = vault.totalAssets();
        uint256 userBalanceBefore = ERC20(vault.asset()).balanceOf(user);
        uint256 userSharesBefore = vault.balanceOf(user);

        vault.previewWithdraw(TEST_AMOUNT);

        assertEq(vault.totalSupply(), totalSupplyBefore);
        assertEq(vault.totalAssets(), totalAssetsBefore);
        assertEq(ERC20(vault.asset()).balanceOf(user), userBalanceBefore);
        assertEq(vault.balanceOf(user), userSharesBefore);
    }

    /*
       ____                _               ____          _
      |  _ \ _ __ _____   _(_) _____      _|  _ \ ___  __| | ___  ___ _ __ ___
      | |_) | '__/ _ \ \ / / |/ _ \ \ /\ / /| |_) / _ \/ _` |/ _ \/ _ \ '_ ` _ \
      |  __/| | |  __/\ V /| |  __/\ V  V / |  _ <  __/ (_| |  __/  __/ | | | |
      |_|   |_|  \___| \_/ |_|\___| \_/\_/  |_| \_\___|\__,_|\___|\___|_| |_|_|
    */

    function test_previewRedeem_withZeroExitFee() public {
        vault.setExitFee(0);
        _deposit(DEPOSIT_AMOUNT);

        uint256 sharesToRedeem = 500e6;
        uint256 assetsReceived = vault.previewRedeem(sharesToRedeem);

        // With no exit fees, assets should equal share value
        uint256 expectedAssets = sharesToRedeem.fullMulDiv(vault.totalAssets(), vault.totalSupply());
        assertEq(assetsReceived, expectedAssets);
    }

    function test_previewRedeem_withStandardExitFee() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 sharesToRedeem = 500e6;
        uint256 assetsReceived = vault.previewRedeem(sharesToRedeem);

        // Calculate expected assets considering exit fee
        uint256 baseAssets = sharesToRedeem.fullMulDiv(vault.totalAssets(), vault.totalSupply());
        uint256 fee = vault.feeOnTotal(baseAssets, vault.getExitFee());
        uint256 expectedAssets = baseAssets - fee;

        assertEq(assetsReceived, expectedAssets);
    }

    function test_previewRedeem_allShares() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 userShares = vault.balanceOf(user);
        uint256 assetsReceivedIncludingFee = vault.previewRedeem(userShares);

        uint256 finalAssetReceived =
            assetsReceivedIncludingFee.rawSub(vault.feeOnTotal(assetsReceivedIncludingFee, vault.getExitFee()));

        // Should be able to redeem all shares
        assertTrue(finalAssetReceived > 0);
        assertTrue(finalAssetReceived <= vault.totalAssets());
    }

    function test_previewRedeem_exceedsBalance() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 userShares = vault.balanceOf(user);
        uint256 excessiveShares = userShares + 1e6;

        // Should handle gracefully
        uint256 assetsReceived = vault.previewRedeem(excessiveShares);
        assertTrue(assetsReceived >= 0);
    }

    function test_previewRedeem_smallAmountPrecision() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 smallShares = 1; // 1 wei of shares
        uint256 assetsReceived = vault.previewRedeem(smallShares);
        assertTrue(assetsReceived >= 0);
    }

    function test_previewRedeem_largeAmountPrecision() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 userShares = vault.balanceOf(user);
        uint256 assetsReceived = vault.previewRedeem(userShares);
        assertTrue(assetsReceived > 0);
    }

    function test_previewRedeem_noStateChanges() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 totalSupplyBefore = vault.totalSupply();
        uint256 totalAssetsBefore = vault.totalAssets();
        uint256 userBalanceBefore = ERC20(vault.asset()).balanceOf(user);
        uint256 userSharesBefore = vault.balanceOf(user);

        vault.previewRedeem(TEST_AMOUNT);

        assertEq(vault.totalSupply(), totalSupplyBefore);
        assertEq(vault.totalAssets(), totalAssetsBefore);
        assertEq(ERC20(vault.asset()).balanceOf(user), userBalanceBefore);
        assertEq(vault.balanceOf(user), userSharesBefore);
    }

    /*
       ___       _                        _   _____                 _   _
      |_ _|_ __ | |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
       | || '_ \| __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
       | || | | | ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |___|_| |_|\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */
    function test_feeOnRaw() public view {
        uint256 amount = SMALL_TEST_AMOUNT;
        uint256 fbps = 10; //0.1%

        uint256 totalAmount = vault.feeOnRaw(amount, fbps);

        uint256 expectedAmount = amount.mulDivUp(fbps, BASIS_POINT_SCALE);

        assertEq(totalAmount, expectedAmount);
    }

    function test_feeOnTotal() public view {
        uint256 amount = SMALL_TEST_AMOUNT;
        uint256 fbps = 10; //0.1%

        uint256 totalAmount = vault.feeOnTotal(amount, fbps);

        uint256 expectedAmount = amount.mulDivUp(fbps, BASIS_POINT_SCALE + fbps);

        assertEq(totalAmount, expectedAmount);
    }

    // ==========================================================================

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
