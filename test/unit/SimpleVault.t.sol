// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {SimpleStrategy} from "../../src/SimpleStrategy.sol";

import {HelperConfig} from "../../script/HelperConfig.s.sol";

/// @title SimpleVaultTest
/// @notice Comprehensive test suite for SimpleVault functionality
/// @dev Tests vault operations, fee calculations, and strategy integration using mainnet fork
/// @author megabyte0x.eth
contract SimpleVaultTest is Test {
    using FixedPointMathLib for uint256;

    /// @notice SimpleVault contract instance under test
    SimpleVault vault;

    /// @notice SimpleStrategy contract instance for yield generation
    SimpleStrategy strategy;

    /// @notice Network configuration containing protocol addresses
    HelperConfig.NetworkConfig networkConfig;

    /// @notice Address that receives vault fees
    address feeRecipient;

    /// @notice Test user address for vault operations
    address user;

    /// @notice Amount of USDC to mint for testing (100M USDC)
    uint256 public constant USDC_TO_MINT = 100_000_000e6;

    /// @notice Standard deposit amount for tests (100k USDC)
    uint256 public constant DEPOSIT_AMOUNT = 100_000e6;

    /// @notice Scale factor for basis points calculations
    uint256 public constant BASIS_POINT_SCALE = 1e4;

    /// @notice Sets up test environment with vault, strategy, and test accounts
    /// @dev Creates fresh contracts and configures them with network-specific addresses
    function setUp() public {
        HelperConfig config = new HelperConfig();
        networkConfig = config.getNetworkConfig();

        // Deploy vault and strategy contracts
        vault = new SimpleVault(networkConfig.usdc);
        strategy = new SimpleStrategy(address(vault), networkConfig.aave_pool, networkConfig.morpho_vault);

        // Create test addresses
        feeRecipient = makeAddr("FEE_RECIPIENT");
        user = makeAddr("USER");

        // Configure vault with strategy and fees
        vault.setStrategy(address(strategy));
        vault.setEntryFee(networkConfig.entryFee);
        vault.setExitFee(networkConfig.exitFee);
        vault.setFeeRecipient(feeRecipient);

        // Transfer USDC from whale to test user
        vm.prank(networkConfig.usdc_holder);
        IERC20(networkConfig.usdc).transfer(user, USDC_TO_MINT);
    }

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

        uint256 expected_supply =
            DEPOSIT_AMOUNT.rawSub(DEPOSIT_AMOUNT.mulDivUp(networkConfig.entryFee, BASIS_POINT_SCALE));

        assertEq(expected_supply, vault.totalSupply());
    }

    /// @notice Fuzz test for deposit functionality with various amounts
    /// @dev Tests deposit amounts from 1 USDC to 100M USDC
    /// @param depositAmount Random deposit amount to test (bounded)
    function testFuzz_deposit(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        vm.startPrank(user);
        IERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        uint256 expected_supply = depositAmount - depositAmount.mulDivUp(networkConfig.entryFee, BASIS_POINT_SCALE);

        assertEq(expected_supply, vault.totalSupply());
    }

    /// @notice Tests basic withdrawal functionality with exit fee calculation
    /// @dev Verifies that user receives withdrawal amount minus exit fees
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

    /// @notice Fuzz test for withdrawal functionality with various amounts
    /// @dev Tests withdrawal amounts up to the maximum allowed for the user
    /// @param depositAmount Random deposit amount (bounded)
    /// @param withdrawAmount Random withdrawal amount (bounded by max withdraw)
    function testFuzz_withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        _deposit(depositAmount);

        uint256 maxWithdraw = vault.maxWithdraw(user);

        //! TODO: Remove debug console log before production
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

    /// @notice Fuzz test for withdrawals when vault has sufficient unallocated funds
    /// @dev Tests scenario where withdrawal doesn't require asset reallocation from protocols
    /// @param depositAmount Random deposit amount (bounded)
    /// @param withdrawAmount Random withdrawal amount (bounded by unallocated funds)
    function testFuzz_withdraw_WhenUnallocatedFundsAreGreaterThanWithdrawAmount(
        uint256 depositAmount,
        uint256 withdrawAmount
    ) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        _deposit(depositAmount);

        uint256 unallocatedAmount = IERC20(networkConfig.usdc).balanceOf(address(vault));

        uint256 maxWithdraw = unallocatedAmount;

        //! TODO: Remove debug console log before production
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

    /// @notice Tests total assets calculation across vault and external protocols
    /// @dev Verifies that totalAssets equals sum of vault balance and deployed assets
    function test_totalSupply() public {
        _deposit(DEPOSIT_AMOUNT);

        uint256 totalAssets = vault.totalAssets();

        uint256 assetsInVault = IERC20(networkConfig.usdc).balanceOf(address(vault));
        uint256 assetsInMarkets = strategy.getTotalBalanceInMarkets();

        uint256 expectedAssets = assetsInVault + assetsInMarkets;

        assertEq(totalAssets, expectedAssets);
    }

    /// @notice Fuzz test for total assets calculation with various deposit amounts
    /// @dev Ensures totalAssets calculation is correct across different vault sizes
    /// @param depositAmount Random deposit amount to test (bounded)
    function testFuzz_totalSupply(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, 100_000_000e6);

        _deposit(depositAmount);

        uint256 totalAssets = vault.totalAssets();

        uint256 assetsInVault = IERC20(networkConfig.usdc).balanceOf(address(vault));
        uint256 assetsInMarkets = strategy.getTotalBalanceInMarkets();

        uint256 expectedAssets = assetsInVault + assetsInMarkets;

        assertEq(totalAssets, expectedAssets);
    }

    /// @notice Internal helper function to perform deposit operations
    /// @dev Handles approval and deposit in a single transaction
    /// @param depositAmount Amount of USDC to deposit
    function _deposit(uint256 depositAmount) internal {
        vm.startPrank(user);
        IERC20(networkConfig.usdc).approve(address(vault), depositAmount);
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
