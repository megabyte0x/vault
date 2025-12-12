// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import {SimpleVault} from "../../src/SimpleVault.sol";
import {SimpleStrategy} from "../../src/SimpleStrategy.sol";

import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract SimpleVaultTest is Test {
    SimpleVault vault;
    SimpleStrategy strategy;

    HelperConfig.NetworkConfig networkConfig;

    address feeRecipient;
    address user;

    uint256 public constant USDC_TO_MINT = 100_000_000e6;

    function setUp() public {
        HelperConfig config = new HelperConfig();
        networkConfig = config.getNetworkConfig();

        vault = new SimpleVault(networkConfig.usdc);

        strategy = new SimpleStrategy(address(vault), networkConfig.aave_pool, networkConfig.morpho_vault);

        feeRecipient = makeAddr("FEE_RECIPIENT");
        user = makeAddr("USER");

        vault.setStrategy(address(strategy));
        vault.setEntryFee(networkConfig.entryFee);
        vault.setExitFee(networkConfig.exitFee);
        vault.setFeeRecipient(feeRecipient);

        vm.prank(networkConfig.usdc_holder);
        IERC20(networkConfig.usdc).transfer(user, USDC_TO_MINT);
    }

    function test_symbol() public view {
        assertEq(vault.symbol(), "SV");
    }

    function test_name() public view {
        assertEq(vault.name(), "Simple Vault");
    }

    function test_asset() public view {
        assertEq(vault.asset(), networkConfig.usdc);
    }

    function test_deposit() public {
        uint256 depositAmount = 100_000e6;

        vm.startPrank(user);
        IERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
    }
}
