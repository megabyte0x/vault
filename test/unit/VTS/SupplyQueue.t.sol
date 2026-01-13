// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Errors} from "../../../src/lib/Errors.sol";
import {MockTokenizedStrategy, BaseTestForVTS} from "../../BaseTestForVTS.t.sol";

contract SupplyQueueTest__VTS is BaseTestForVTS {
    modifier addStrategies() {
        _addStrategies();
        _;
    }

    /**
     * @notice verifies if the supply queue is updated successfully.
     */
    function test_updateSupplyQueue() public addStrategies {
        uint256[] memory newSupplyQueue = new uint256[](5);
        newSupplyQueue[0] = 4;
        newSupplyQueue[1] = 3;
        newSupplyQueue[2] = 1;
        newSupplyQueue[4] = 0;
        newSupplyQueue[3] = 2;

        vm.prank(allocator);
        vault.updateSupplyQueue(newSupplyQueue);

        uint256[] memory supplyQueue = vault.getSupplyQueue();

        assertEq(supplyQueue, newSupplyQueue);
    }

    function test_RevertWhen_newSupplyQueueLengthIsGreaterThanMaxStrategies() public addStrategies {
        uint256[] memory newSupplyQueue = new uint256[](vault.getMaxStrategies() + 1);

        vm.prank(allocator);
        vm.expectRevert(Errors.MaxStrategiesReached.selector);
        vault.updateSupplyQueue(newSupplyQueue);
    }

    function _addStrategies() public {
        for (uint256 i = 0; i < 5; i++) {
            MockTokenizedStrategy newStrategy = new MockTokenizedStrategy(address(yieldSource), address(vault));

            vm.prank(curator);
            vault.addStrategy(address(newStrategy), STANDARD_STRATEGY_CAP);
        }
    }
}
