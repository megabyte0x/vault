// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "../../src/lib/Errors.sol";
import {MockTokenizedStrategy, BaseTestForVTS, VTS} from "../BaseTestForVTS.t.sol";

contract SimpleVaultWithTokenizedStrategyTest is BaseTestForVTS {
    using FixedPointMathLib for uint256;

    function test_constructor() public {
        VTS newTSV = new VTS(networkConfig.usdc);

        assertEq(newTSV.asset(), networkConfig.usdc);
    }

    /*
       _______  _______ _____ ____  _   _    _    _       _____ _   _ _   _  ____ _____ ___ ___  _   _ ____
      | ____\ \/ /_   _| ____|  _ \| \ | |  / \  | |     |  ___| | | | \ | |/ ___|_   _|_ _/ _ \| \ | / ___|
      |  _|  \  /  | | |  _| | |_) |  \| | / _ \ | |     | |_  | | | |  \| | |     | |  | | | | |  \| \___ \
      | |___ /  \  | | | |___|  _ <| |\  |/ ___ \| |___  |  _| | |_| | |\  | |___  | |  | | |_| | |\  |___) |
      |_____/_/\_\ |_| |_____|_| \_\_| \_/_/   \_\_____| |_|    \___/|_| \_|\____| |_| |___\___/|_| \_|____/
    */

    function test_setEntryFee() public {
        uint256 entryFeeInBPS = 100;

        vm.prank(manager);
        vault.setEntryFee(entryFeeInBPS);

        assertEq(vault.getEntryFee(), entryFeeInBPS);
    }

    function test_setExitFee() public {
        uint256 exitFeeInBps = 100;

        vm.prank(manager);
        vault.setExitFee(exitFeeInBps);

        assertEq(vault.getExitFee(), exitFeeInBps);
    }

    function test_setFeeRecipient() public {
        address newFeeRecipient = makeAddr("newRecipient");

        vm.prank(manager);
        vault.setFeeRecipient(newFeeRecipient);

        assertEq(vault.getFeeRecipient(), newFeeRecipient);
    }

    function test_setFeeRecipient_withZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);

        vm.prank(manager);
        vault.setFeeRecipient(address(0));
    }

    function test_mimumIdleAssets() public {
        uint256 minIdleAssets = 50; // 50 bps = 0.5 %

        vm.prank(curator);
        vault.setMinimumIdleAssets(minIdleAssets);

        assertEq(vault.getMinimumIdleAssets(), minIdleAssets);
    }

    function test_addStrategy_FirstStrategyWithEmptyVault() public {
        uint256 allocation = 90_00; // 90%

        vm.prank(curator);
        vault.addStrategy(address(strategy), allocation);

        uint256 currentStrategyIndex = vault.getStrategyIndex(address(strategy));
        uint256 expectedStrategyIndex = 0;

        assertEq(currentStrategyIndex, expectedStrategyIndex);

        uint256 currentTotalStrategies = vault.getTotalStrategies();
        uint256 expectedTotalStrategies = 1;

        assertEq(currentTotalStrategies, expectedTotalStrategies);
    }

    function test_addStrategy_FirstStrategy() public {
        uint256 allocation = 90_00; // 90%

        _deposit(DEPOSIT_AMOUNT);

        uint256 feeAmount = DEPOSIT_AMOUNT.mulDivUp(vault.getEntryFee(), vault.getEntryFee() + BASIS_POINT_SCALE);
        uint256 finalDepositAmount = DEPOSIT_AMOUNT.rawSub(feeAmount);

        _addStrategy(allocation);

        uint256 assetsInStrategy = vault.getAssetInStrategy(address(strategy));

        uint256 expectedAssetsInStrategy = finalDepositAmount.mulDiv(allocation, BASIS_POINT_SCALE);

        assertEq(assetsInStrategy, expectedAssetsInStrategy);
    }

    function test_addStrategy_SecondStrategy() public {
        uint256 firstStrategyAllocation = 85_00;
        uint256 secondStrategyAllocation = 12_00;

        uint256 feeAmount = DEPOSIT_AMOUNT.mulDivUp(vault.getEntryFee(), vault.getEntryFee() + BASIS_POINT_SCALE);
        uint256 finalDepositAmount = DEPOSIT_AMOUNT.rawSub(feeAmount);

        _deposit(DEPOSIT_AMOUNT);
        _addStrategy(firstStrategyAllocation);

        MockTokenizedStrategy strategy2 = new MockTokenizedStrategy(address(yieldSource), address(vault));

        vm.prank(curator);
        vault.addStrategy(address(strategy2), secondStrategyAllocation);

        uint256 assetsInStrategy1 = vault.getAssetInStrategy(address(strategy));
        uint256 assetsInStrategy2 = vault.getAssetInStrategy(address(strategy2));

        uint256 expectedAssetsInStrategy1 = finalDepositAmount.mulDiv(firstStrategyAllocation, BASIS_POINT_SCALE);
        uint256 expectedAssetsInStrategy2 = finalDepositAmount.mulDiv(secondStrategyAllocation, BASIS_POINT_SCALE);

        assertEq(assetsInStrategy1, expectedAssetsInStrategy1);
        assertEq(assetsInStrategy2, expectedAssetsInStrategy2);

        uint256 totalAssets = vault.totalAssets();
        uint256 expectedTotalAssets = finalDepositAmount;

        assertEq(totalAssets, expectedTotalAssets);
    }

    function test_addStrategy_StrategyWithZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(curator);
        vault.addStrategy(address(0), 0);
    }

    function test_addStrategy_StrategyAlreadyAdded() public {
        uint256 allocation = 90_00; // 90%

        vm.startPrank(curator);
        vault.addStrategy(address(strategy), allocation);
        vm.expectRevert(Errors.StrategyAlreadyAdded.selector);
        vault.addStrategy(address(strategy), BASIS_POINT_SCALE.rawSub(allocation));
        vm.stopPrank();
    }

    function test_addStrategy_StrategyExceedingTotalAllocation() public {
        uint256 minimumIdleAssetAllocation = 5_00; // 5%

        vm.prank(curator);
        vault.setMinimumIdleAssets(minimumIdleAssetAllocation);

        uint256 allocation = 96_00; // 96%

        vm.prank(curator);
        vm.expectRevert(Errors.TotalAllocationExceeded.selector);
        vault.addStrategy(address(strategy), allocation);
    }

    function test_addStrategy_StrategyWithZeroAllocation() public {
        vm.prank(curator);

        vm.expectRevert(Errors.ZeroAmount.selector);
        vault.addStrategy(address(strategy), 0);
    }

    /*
       ____  _   _ ____  _     ___ ____   _____ _   _ _   _  ____ _____ ___ ___  _   _ ____
      |  _ \| | | | __ )| |   |_ _/ ___| |  ___| | | | \ | |/ ___|_   _|_ _/ _ \| \ | / ___|
      | |_) | | | |  _ \| |    | | |     | |_  | | | |  \| | |     | |  | | | | |  \| \___ \
      |  __/| |_| | |_) | |___ | | |___  |  _| | |_| | |\  | |___  | |  | | |_| | |\  |___) |
      |_|    \___/|____/|_____|___\____| |_|    \___/|_| \_|\____| |_| |___\___/|_| \_|____/
    */

    function test_name() public view {
        string memory currentName = vault.name();
        string memory expectedName = "Simple Vault w/ Tokenized Strategy";

        assertEq(currentName, expectedName);
    }

    function test_symbol() public view {
        string memory currentSymbol = vault.symbol();
        string memory expectedSymbol = "SVTS";

        assertEq(currentSymbol, expectedSymbol);
    }

    function test_asset() public view {
        assertEq(vault.asset(), networkConfig.usdc);
    }

    /*
       ___ _   _ _____ _____ ____  _   _    _    _       _____ _   _ _   _  ____ _____ ___ ___  _   _ ____
      |_ _| \ | |_   _| ____|  _ \| \ | |  / \  | |     |  ___| | | | \ | |/ ___|_   _|_ _/ _ \| \ | / ___|
       | ||  \| | | | |  _| | |_) |  \| | / _ \ | |     | |_  | | | |  \| | |     | |  | | | | |  \| \___ \
       | || |\  | | | | |___|  _ <| |\  |/ ___ \| |___  |  _| | |_| | |\  | |___  | |  | | |_| | |\  |___) |
      |___|_| \_| |_| |_____|_| \_\_| \_/_/   \_\_____| |_|    \___/|_| \_|\____| |_| |___\___/|_| \_|____/
    */

    function test_underlyingDecimals() public view {
        uint8 currentDecimals = vault.underlyingDecimals();

        uint8 epxectedDecimals = ERC20(networkConfig.usdc).decimals();

        assertEq(currentDecimals, epxectedDecimals);
    }

    // ==========================================================================

    /**
     *
     * @notice Internal helper function to perform deposit operations
     * @dev Handles approval and deposit in a single transaction
     * @param depositAmount Amount of USDC to deposit
     */
    function _deposit(uint256 depositAmount) internal {
        vm.startPrank(user);
        ERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
    }

    /**
     *
     * @notice Internal helper function to perform withdrawal operations
     * @dev Withdraws specified amount to user's address
     * @param withdrawAmount Amount of assets to withdraw
     */
    function _withdraw(uint256 withdrawAmount) internal {
        vm.prank(user);
        vault.withdraw(withdrawAmount, user, user);
    }

    function _addStrategy(uint256 allocation) internal {
        vm.prank(curator);
        vault.addStrategy(address(strategy), allocation);
    }
}
