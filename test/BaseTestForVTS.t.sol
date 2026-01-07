// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {SimpleVaultWithTokenizedStrategyHarness as VTS} from "./harness/SimpleVaultWithTokenizedStrategyHarness.sol";
import {MockTokenizedStrategy} from "./mock/MockTokenizedStrategy.sol";
import {MockYieldSource} from "./mock/MockYieldSource.sol";

import {HelperConfig} from "../script/HelperConfig.s.sol";

/// @title BaseTestForVTS (VTS = Vault w/ Tokenized Strategy)
/// @notice Comprehensive test suite for SimpleVaultWithTokenizedStrategy functionality
/// @dev Tests vault operations, fee calculations, and strategy integration using mainnet fork
/// @author megabyte0x.eth
contract BaseTestForVTS is Test {
    using SafeTransferLib for address;

    /// @notice SimpleVault contract instance under test
    VTS vault;

    /// @notice SimpleStrategy contract instance for yield generation
    MockTokenizedStrategy strategy;

    MockYieldSource yieldSource;

    /// @notice Network configuration containing protocol addresses
    HelperConfig.NetworkConfig networkConfig;

    /// @notice Address that receives vault fees
    address feeRecipient;

    /// @notice Test user address for vault operations
    address user;

    address manager;

    address curator;

    address allocator;

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

    bytes32 public constant ALLOCATOR_ROLE = keccak256("ALLOCATOR");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    /// @notice Sets up test environment with vault, strategy, and test accounts
    /// @dev Creates fresh contracts and configures them with network-specific addresses
    function setUp() public virtual {
        HelperConfig config = new HelperConfig();
        networkConfig = config.getNetworkConfig();

        // Deploy vault and strategy contracts
        vault = new VTS(networkConfig.usdc);

        yieldSource = new MockYieldSource();

        strategy = new MockTokenizedStrategy(address(yieldSource), address(vault));

        // Create test addresses
        feeRecipient = makeAddr("FEE_RECIPIENT");
        user = makeAddr("USER");
        manager = makeAddr("MANAGER");
        curator = makeAddr("CURATOR");
        allocator = makeAddr("ALLOCATOR");

        _setRoles();

        _setFeeConfig();

        // Transfer USDC from whale to test user
        vm.prank(networkConfig.usdc_holder);
        (networkConfig.usdc).safeTransfer(user, USDC_TO_MINT);
    }

    function _setRoles() internal {
        vault.grantRole(MANAGER_ROLE, manager);
        vault.grantRole(CURATOR_ROLE, curator);
        vault.grantRole(ALLOCATOR_ROLE, allocator);
    }

    /**
     * @notice Configure vault with fees
     */
    function _setFeeConfig() internal {
        vm.startPrank(manager);
        vault.setEntryFee(networkConfig.entryFee);
        vault.setExitFee(networkConfig.exitFee);
        vault.setFeeRecipient(feeRecipient);
        vm.stopPrank();
    }
}
