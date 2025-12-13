// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract SimpleVault__Initialize is Script {
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

    function initializeVault() internal {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        address vault = config.getVault();
        address strategy = config.getStrategy();

        initializeVaultWithConfigs(
            SimpleVault(vault), strategy, config.FEE_RECIPIENT(), networkConfig.entryFee, networkConfig.exitFee
        );
    }

    function run() public {
        initializeVault();
    }
}

contract SimpleVault__Deposit is Script {
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

    function deposit() internal {
        HelperConfig config = new HelperConfig();
        address vault = config.getVault();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        uint256 depositAmount = 100_000e6;

        depositWithConfigs(vault, config.USER(), depositAmount, networkConfig);
    }

    function run() public {
        deposit();
    }
}
