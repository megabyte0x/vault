// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

/// @title SimpleVault__Initialize
/// @notice Script to initialize a deployed SimpleVault with strategy and fee configuration
/// @dev Sets up entry/exit fees, fee recipient, and strategy contract
/// @author megabyte0x.eth
contract SimpleVault__Initialize is Script {
    /// @notice Initializes vault with specified configuration parameters
    /// @dev Calls all setter functions to configure the vault completely
    /// @param vault The SimpleVault contract instance to configure
    /// @param strategy Address of the strategy contract to set
    /// @param feeRecipient Address that will receive collected fees
    /// @param entryFee Entry fee in basis points
    /// @param exitFee Exit fee in basis points
    function initializeVaultWithConfigs(
        SimpleVault vault,
        address strategy,
        address feeRecipient,
        uint256 entryFee,
        uint256 exitFee
    ) internal {
        vm.startBroadcast();
        vault.setEntryFee(entryFee);
        vault.setExitFee(exitFee);
        vault.setFeeRecipient(feeRecipient);
        vault.setStrategy(strategy);
        vm.stopBroadcast();
    }

    /// @notice Initializes vault using network configuration
    /// @dev Gets deployed contract addresses and network-specific parameters from HelperConfig
    function initializeVault() internal {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        address vault = config.getVault();
        address strategy = config.getStrategy();

        initializeVaultWithConfigs(
            SimpleVault(vault), strategy, config.FEE_RECIPIENT(), networkConfig.entryFee, networkConfig.exitFee
        );
    }

    /// @notice Main entry point for initialization script
    /// @dev Called by `forge script` command to execute vault initialization
    function run() public {
        initializeVault();
    }
}

/// @title SimpleVault__Deposit
/// @notice Script to perform a test deposit into the SimpleVault
/// @dev Approves USDC spending and deposits a fixed amount for testing
/// @author megabyte0x.eth
contract SimpleVault__Deposit is Script {
    /// @notice Performs deposit with specified configuration
    /// @dev Approves USDC spending and calls vault's deposit function
    /// @param vault Address of the SimpleVault contract
    /// @param user Address that will receive the vault shares
    /// @param depositAmount Amount of USDC to deposit (in USDC decimals)
    /// @param networkConfig Network configuration containing USDC address
    //! TODO: Add error handling for insufficient balance or approval failures
    function depositWithConfigs(
        address vault,
        address user,
        uint256 depositAmount,
        HelperConfig.NetworkConfig memory networkConfig
    ) internal {
        vm.startBroadcast();
        IERC20(networkConfig.usdc).approve(vault, depositAmount);
        SimpleVault(vault).deposit(depositAmount, user);
    }

    /// @notice Performs a test deposit using network configuration
    /// @dev Deposits 100,000 USDC (100k * 1e6) to the test user address
    function deposit() internal {
        HelperConfig config = new HelperConfig();
        address vault = config.getVault();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        uint256 depositAmount = 100_000e6; // 100,000 USDC

        depositWithConfigs(vault, config.USER(), depositAmount, networkConfig);
    }

    /// @notice Main entry point for deposit script
    /// @dev Called by `forge script` command to execute test deposit
    function run() public {
        deposit();
    }
}
