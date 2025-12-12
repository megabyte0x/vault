// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

import {SimpleStrategy} from "../../src/SimpleStrategy.sol";

import {HelperConfig} from "../HelperConfig.s.sol";

contract DeploySimpleStrategy is Script {
    function deploySimpleStrategyUsingConfigs(address vault, HelperConfig.NetworkConfig memory networkConfig) internal {
        vm.broadcast();
        new SimpleStrategy(vault, networkConfig.aave_pool, networkConfig.morpho_vault);
    }

    function deploySimpleStrategy() internal {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();
        address vault = config.getVault();

        deploySimpleStrategyUsingConfigs(vault, networkConfig);
    }

    function run() public {
        deploySimpleStrategy();
    }
}
