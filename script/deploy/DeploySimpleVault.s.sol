// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DeploySimpleVault is Script {
    function deploySimpleVaultUsingConfigs(address _asset) internal {
        vm.broadcast();
        new SimpleVault(_asset);
    }

    function deploySimpleVault() internal {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        deploySimpleVaultUsingConfigs(networkConfig.usdc);
    }

    function run() public {
        deploySimpleVault();
    }
}
