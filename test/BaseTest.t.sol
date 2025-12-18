// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {SimpleVaultHarness} from "./harness/SimpleVaultHarness.sol";
import {SimpleStrategy} from "../src/SimpleStrategy.sol";

import {HelperConfig} from "../script/HelperConfig.s.sol";

/// @title BaseTest
/// @notice Comprehensive test suite for SimpleVault functionality
/// @dev Tests vault operations, fee calculations, and strategy integration using mainnet fork
/// @author megabyte0x.eth
contract BaseTest is Test {
    using SafeTransferLib for address;

    /// @notice SimpleVault contract instance under test
    SimpleVaultHarness vault;

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

    /// @notice Test amount for various operations (1000 USDC)
    uint256 public constant TEST_AMOUNT = 1000e6;

    /// @notice Small test amount for edge cases (100 USDC)
    uint256 public constant SMALL_TEST_AMOUNT = 100e6;

    /// @notice Sets up test environment with vault, strategy, and test accounts
    /// @dev Creates fresh contracts and configures them with network-specific addresses
    function setUp() public {
        HelperConfig config = new HelperConfig();
        networkConfig = config.getNetworkConfig();

        // Deploy vault and strategy contracts
        vault = new SimpleVaultHarness(networkConfig.usdc);
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
        (networkConfig.usdc).safeTransfer(user, USDC_TO_MINT);
    }
}
