// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {BaseTest} from "../BaseTest.t.sol";

/// @title SimpleVaultTest
/// @notice Comprehensive test suite for SimpleVault functionality
/// @dev Tests vault operations, fee calculations, and strategy integration using mainnet fork
/// @author megabyte0x.eth
contract SimpleStrategyTest is BaseTest {
    function test_asset() public view {
        assertEq(strategy.asset(), vault.asset());
    }
}
