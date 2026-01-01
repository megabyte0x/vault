// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "@devops/src/DevOpsTools.sol";

import {MockUSDC} from "../test/mock/MockUSDC.sol";

/// @title HelperConfig
/// @notice Configuration contract for different network deployments
/// @dev Provides network-specific addresses and parameters for vault deployment
/// @author megabyte0x.eth
contract HelperConfig is Script {
    /// @notice Configuration parameters for a specific network
    /// @param usdc Address of the USDC token contract
    /// @param morpho_vault Address of the Morpho vault for USDC
    /// @param aave_pool Address of the Aave lending pool
    /// @param usdc_holder Address with large USDC balance (for testing)
    /// @param entryFee Entry fee in basis points
    /// @param exitFee Exit fee in basis points
    struct NetworkConfig {
        address usdc;
        address morpho_vault;
        address aave_pool;
        address usdc_holder;
        uint256 entryFee;
        uint256 exitFee;
    }

    /// @notice Ethereum mainnet USDC token address
    address internal constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @notice Ethereum mainnet Morpho USDC vault address
    address internal constant ETH_MORPHO_VAULT = 0xbeeff2C5bF38f90e3482a8b19F12E5a6D2FCa757;

    /// @notice Ethereum mainnet Aave v3 Pool address
    address internal constant ETH_AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    /// @notice Ethereum mainnet address with large USDC balance for testing
    address internal constant ETH_USDC_HOLDER = 0xE20d20b0cC4e44Cd23D5B0488D5250A9ac426875;

    /// @notice Default fee recipient address
    address public constant FEE_RECIPIENT = 0xdDCc06f98A7C71Ab602b8247d540dA5BD8f5D2A2;

    /// @notice Default test user address
    address public constant USER = 0xa60f738a60BCA515Ac529b7335EC7CB2eE3891d2;

    /// @notice Default entry fee: 5 basis points (0.05%)
    uint256 internal constant ENTRY_FEE = 5;

    /// @notice Default exit fee: 10 basis points (0.1%)
    uint256 internal constant EXIT_FEE = 10;

    /// @notice Returns the network configuration for the current chain
    /// @dev Currently only supports Ethereum mainnet (chain ID 1)
    /// @return config The network configuration struct
    //! TODO: Add support for other networks (testnets, L2s)
    function getNetworkConfig() public returns (NetworkConfig memory config) {
        if (block.chainid == 1) {
            config = getMainnetConfig();
        } else {
            config = getAnvilConfig();
        }
    }

    /// @notice Returns the address of the most recently deployed SimpleVault
    /// @dev Uses DevOpsTools to find the latest deployment
    /// @return vault The address of the SimpleVault contract
    function getVault() public view returns (address vault) {
        vault = _getAddress("SimpleVault");
    }

    /// @notice Returns the address of the most recently deployed SimpleStrategy
    /// @dev Uses DevOpsTools to find the latest deployment
    /// @return strategy The address of the SimpleStrategy contract
    function getStrategy() public view returns (address strategy) {
        strategy = _getAddress("SimpleStrategy");
    }

    /// @notice Returns the configuration for Ethereum mainnet
    /// @dev Contains all necessary addresses and parameters for mainnet deployment
    /// @return config The mainnet network configuration
    function getMainnetConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            usdc: ETH_USDC,
            morpho_vault: ETH_MORPHO_VAULT,
            aave_pool: ETH_AAVE_POOL,
            entryFee: ENTRY_FEE,
            exitFee: EXIT_FEE,
            usdc_holder: ETH_USDC_HOLDER
        });
    }

    function getAnvilConfig() internal returns (NetworkConfig memory config) {
        config = NetworkConfig({
            usdc: address(new MockUSDC()),
            morpho_vault: makeAddr("morpho_vault"),
            aave_pool: makeAddr("aave_pool"),
            entryFee: ENTRY_FEE,
            exitFee: EXIT_FEE,
            usdc_holder: ETH_USDC_HOLDER
        });
    }

    /// @notice Internal helper to get the most recent deployment address
    /// @dev Uses Foundry DevOpsTools to retrieve deployment addresses
    /// @param contractName The name of the contract to find
    /// @return The address of the most recently deployed contract
    function _getAddress(string memory contractName) internal view returns (address) {
        return DevOpsTools.get_most_recent_deployment(contractName, block.chainid);
    }
}
