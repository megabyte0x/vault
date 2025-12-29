// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

import {SimpleStrategy} from "../../src/SimpleStrategy.sol";

import {HelperConfig} from "../HelperConfig.s.sol";

/// @title DeploySimpleStrategy
/// @notice Deployment script for SimpleStrategy contract
/// @dev Requires SimpleVault to be deployed first, uses HelperConfig for network addresses
/// @author megabyte0x.eth
contract DeploySimpleStrategy is Script {
    /// @notice Deploys SimpleStrategy with specified configuration
    /// @dev Uses vm.broadcast() for actual deployment transaction
    /// @param vault Address of the SimpleVault that will use this strategy
    /// @param networkConfig Network configuration containing Aave and Morpho addresses
    function deploySimpleStrategyUsingConfigs(address vault, HelperConfig.NetworkConfig memory networkConfig) internal {
        vm.broadcast();
        new SimpleStrategy(vault, networkConfig.aave_pool, networkConfig.morpho_vault);
    }

    /// @notice Deploys SimpleStrategy using network-specific configuration
    /// @dev Gets vault address from previous deployment and network config for protocols
    function deploySimpleStrategy() internal {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();
        address vault = config.getVault();

        deploySimpleStrategyUsingConfigs(vault, networkConfig);
    }

    /// @notice Main entry point for deployment script
    /// @dev Called by `forge script` command to execute deployment
    function run() public {
        deploySimpleStrategy();
    }
}
