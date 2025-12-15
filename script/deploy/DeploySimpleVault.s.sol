// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

/// @title DeploySimpleVault
/// @notice Deployment script for SimpleVault contract
/// @dev Uses HelperConfig to get network-specific asset addresses
/// @author megabyte0x.eth
contract DeploySimpleVault is Script {
    /// @notice Deploys SimpleVault with specified asset address
    /// @dev Uses vm.broadcast() for actual deployment transaction
    /// @param _asset Address of the underlying asset (e.g., USDC)
    function deploySimpleVaultUsingConfigs(address _asset) internal {
        vm.broadcast();
        new SimpleVault(_asset);
    }

    /// @notice Deploys SimpleVault using network-specific configuration
    /// @dev Creates HelperConfig instance to get USDC address for current network
    function deploySimpleVault() internal {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        deploySimpleVaultUsingConfigs(networkConfig.usdc);
    }

    /// @notice Main entry point for deployment script
    /// @dev Called by `forge script` command to execute deployment
    function run() public {
        deploySimpleVault();
    }
}
