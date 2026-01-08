// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "../../src/lib/Errors.sol";
import {BaseTestForVTS, VTS} from "../BaseTestForVTS.t.sol";

contract VTSTest is BaseTestForVTS {
    using FixedPointMathLib for uint256;

    function test_constructor() public {
        VTS newTSV = new VTS(networkConfig.usdc, address(this));

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
}
