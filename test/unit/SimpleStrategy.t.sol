// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseTest} from "../BaseTest.t.sol";

/// @title SimpleStrategyTest
/// @notice Tests fro SimleStrategy.
/// @author megabyte0x.eth
contract SimpleStrategyTest is BaseTest {
    function test_asset() public view {
        assertEq(strategy.asset(), vault.asset());
    }
}
