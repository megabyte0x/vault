// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {SimpleStrategy} from "../../src/SimpleStrategy.sol";

import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract SimpleVaultTest is Test {
    using FixedPointMathLib for uint256;

    SimpleVault vault;
    SimpleStrategy strategy;

    HelperConfig.NetworkConfig networkConfig;

    address feeRecipient;
    address user;

    uint256 public constant USDC_TO_MINT = 100_000_000e6;
    uint256 public constant DEPOSIT_AMOUNT = 100_000e6;
    uint256 public constant BASIS_POINT_SCALE = 1e4;

    function setUp() public {
        HelperConfig config = new HelperConfig();
        networkConfig = config.getNetworkConfig();

        vault = new SimpleVault(networkConfig.usdc);

        strategy = new SimpleStrategy(address(vault), networkConfig.aave_pool, networkConfig.morpho_vault);

        feeRecipient = makeAddr("FEE_RECIPIENT");
        user = makeAddr("USER");

        vault.setStrategy(address(strategy));
        vault.setEntryFee(networkConfig.entryFee);
        vault.setExitFee(networkConfig.exitFee);
        vault.setFeeRecipient(feeRecipient);

        vm.prank(networkConfig.usdc_holder);
        IERC20(networkConfig.usdc).transfer(user, USDC_TO_MINT);
    }

    function test_symbol() public view {
        assertEq(vault.symbol(), "SV");
    }

    function test_name() public view {
        assertEq(vault.name(), "Simple Vault");
    }

    function test_asset() public view {
        assertEq(vault.asset(), networkConfig.usdc);
    }

    function test_deposit() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 expected_supply =
            DEPOSIT_AMOUNT.rawSub(DEPOSIT_AMOUNT.mulDivUp(networkConfig.entryFee, BASIS_POINT_SCALE));

        assertEq(expected_supply, vault.totalSupply());
    }

    function testFuzz_deposit(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        vm.startPrank(user);
        IERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        uint256 expected_supply = depositAmount - depositAmount.mulDivUp(networkConfig.entryFee, BASIS_POINT_SCALE);

        assertEq(expected_supply, vault.totalSupply());
    }

    function test_withdraw() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 balanceBeforeWithdraw = IERC20(networkConfig.usdc).balanceOf(user);

        uint256 withdrawAmount = 90_000e6;

        _withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = IERC20(networkConfig.usdc).balanceOf(user);

        uint256 changeInBalance = balanceAfterWithdraw.rawSub(balanceBeforeWithdraw);

        uint256 expectedChangeInBalance =
            withdrawAmount.rawSub(withdrawAmount.mulDivUp(vault.getExitFee(), BASIS_POINT_SCALE));

        assertEq(changeInBalance, expectedChangeInBalance);
    }

    function testFuzz_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        _deposit(depositAmount);

        uint256 maxWithdraw = vault.maxWithdraw(user);

        console2.log("Max withdraw: ", maxWithdraw);

        withdrawAmount = bound(withdrawAmount, 1, maxWithdraw);

        uint256 balanceBeforeWithdraw = IERC20(networkConfig.usdc).balanceOf(user);

        _withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = IERC20(networkConfig.usdc).balanceOf(user);

        uint256 changeInBalance = balanceAfterWithdraw.rawSub(balanceBeforeWithdraw);

        uint256 expectedChangeInBalance =
            withdrawAmount.rawSub(withdrawAmount.mulDivUp(vault.getExitFee(), BASIS_POINT_SCALE));

        assertEq(changeInBalance, expectedChangeInBalance);
    }

    function testFuzz_withdraw_WhenUnallocatedFundsAreGreaterThanWithdrawAmount(
        uint256 depositAmount,
        uint256 withdrawAmount
    ) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        _deposit(depositAmount);

        uint256 unallocatedAmount = IERC20(networkConfig.usdc).balanceOf(address(vault));

        uint256 maxWithdraw = unallocatedAmount;

        console2.log("Max withdraw: ", maxWithdraw);

        withdrawAmount = bound(withdrawAmount, 1, maxWithdraw);

        uint256 balanceBeforeWithdraw = IERC20(networkConfig.usdc).balanceOf(user);

        _withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = IERC20(networkConfig.usdc).balanceOf(user);

        uint256 changeInBalance = balanceAfterWithdraw.rawSub(balanceBeforeWithdraw);

        uint256 expectedChangeInBalance =
            withdrawAmount.rawSub(withdrawAmount.mulDivUp(vault.getExitFee(), BASIS_POINT_SCALE));

        assertEq(changeInBalance, expectedChangeInBalance);
    }

    function test_totalSupply() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 totalAssets = vault.totalAssets();

        uint256 assetsInVault = IERC20(networkConfig.usdc).balanceOf(address(vault));
        uint256 assetsInMarkets = strategy.getTotalBalanceInMarkets();

        uint256 expectedAssets = assetsInVault + assetsInMarkets;

        assertEq(totalAssets, expectedAssets);
    }

    function testFuzz_totalSupply(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        _deposit(depositAmount);

        uint256 totalAssets = vault.totalAssets();

        uint256 assetsInVault = IERC20(networkConfig.usdc).balanceOf(address(vault));
        uint256 assetsInMarkets = strategy.getTotalBalanceInMarkets();

        uint256 expectedAssets = assetsInVault + assetsInMarkets;

        assertEq(totalAssets, expectedAssets);
    }

    function _deposit(uint256 depositAmount) internal {
        vm.startPrank(user);
        IERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
    }

    function _withdraw(uint256 withdrawAmount) internal {
        vm.prank(user);
        vault.withdraw(withdrawAmount, user, user);
    }
}
