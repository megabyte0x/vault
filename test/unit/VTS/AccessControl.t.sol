// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {IAccessControl} from "@openzeppelin/access/IAccessControl.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

import {Errors} from "../../../src/lib/Errors.sol";
import {MockTokenizedStrategy, BaseTestForVTS} from "../../BaseTestForVTS.t.sol";

/**
 * @title AccessControl Test Suite for SimpleVaultWithTokenizedStrategy
 * @notice Comprehensive test suite for access control roles and permissions
 * @dev Tests MANAGER, CURATOR, and ALLOCATOR role restrictions and admin controls
 */
contract AccessControl__VTS is BaseTestForVTS {
    using FixedPointMathLib for uint256;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address unauthorized;
    MockTokenizedStrategy strategy2;

    /**
     * @notice Set up test environment
     * @dev Initializes base test, creates unauthorized user and second strategy
     */
    function setUp() public override {
        super.setUp();
        unauthorized = makeAddr("UNAUTHORIZED");
        strategy2 = new MockTokenizedStrategy(address(yieldSource), address(vault));
    }

    /*
     * MANAGER ROLE TESTS
     */

    /**
     * @notice Test that manager can set entry fee
     * @dev Verifies manager role has permission to update entry fee
     */
    function test_SetEntryFee_AsManager() public {
        uint256 newFee = 100; // 1%

        vm.prank(manager);
        vault.setEntryFee(newFee);

        assertEq(vault.getEntryFee(), newFee);
    }

    /**
     * @notice Test that curator cannot set entry fee
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetEntryFee_AsCurator() public {
        uint256 newFee = 100;

        vm.prank(curator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, curator, MANAGER_ROLE)
        );
        vault.setEntryFee(newFee);
    }

    /**
     * @notice Test that allocator cannot set entry fee
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetEntryFee_AsAllocator() public {
        uint256 newFee = 100;

        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, MANAGER_ROLE)
        );
        vault.setEntryFee(newFee);
    }

    /**
     * @notice Test that unauthorized user cannot set entry fee
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetEntryFee_AsUnauthorizedUser() public {
        uint256 newFee = 100;

        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, MANAGER_ROLE)
        );
        vault.setEntryFee(newFee);
    }

    /**
     * @notice Test that manager can set exit fee
     * @dev Verifies manager role has permission to update exit fee
     */
    function test_SetExitFee_AsManager() public {
        uint256 newFee = 200; // 2%

        vm.prank(manager);
        vault.setExitFee(newFee);

        assertEq(vault.getExitFee(), newFee);
    }

    /**
     * @notice Test that curator cannot set exit fee
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetExitFee_AsCurator() public {
        uint256 newFee = 200;

        vm.prank(curator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, curator, MANAGER_ROLE)
        );
        vault.setExitFee(newFee);
    }

    /**
     * @notice Test that allocator cannot set exit fee
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetExitFee_AsAllocator() public {
        uint256 newFee = 200;

        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, MANAGER_ROLE)
        );
        vault.setExitFee(newFee);
    }

    /**
     * @notice Test that unauthorized user cannot set exit fee
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetExitFee_AsUnauthorizedUser() public {
        uint256 newFee = 200;

        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, MANAGER_ROLE)
        );
        vault.setExitFee(newFee);
    }

    /**
     * @notice Test that manager can set fee recipient
     * @dev Verifies manager role has permission to update fee recipient address
     */
    function test_SetFeeRecipient_AsManager() public {
        address newRecipient = makeAddr("NEW_RECIPIENT");

        vm.prank(manager);
        vault.setFeeRecipient(newRecipient);

        assertEq(vault.getFeeRecipient(), newRecipient);
    }

    /**
     * @notice Test that curator cannot set fee recipient
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetFeeRecipient_AsCurator() public {
        address newRecipient = makeAddr("NEW_RECIPIENT");

        vm.prank(curator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, curator, MANAGER_ROLE)
        );
        vault.setFeeRecipient(newRecipient);
    }

    /**
     * @notice Test that allocator cannot set fee recipient
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetFeeRecipient_AsAllocator() public {
        address newRecipient = makeAddr("NEW_RECIPIENT");

        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, MANAGER_ROLE)
        );
        vault.setFeeRecipient(newRecipient);
    }

    /**
     * @notice Test that unauthorized user cannot set fee recipient
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetFeeRecipient_AsUnauthorizedUser() public {
        address newRecipient = makeAddr("NEW_RECIPIENT");

        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, MANAGER_ROLE)
        );
        vault.setFeeRecipient(newRecipient);
    }

    /**
     * @notice Test that fee recipient cannot be set to zero address
     * @dev Expects revert with ZeroAddress error even when called by manager
     */
    function test_RevertWhen_SetFeeRecipient_ZeroAddress() public {
        vm.prank(manager);
        vm.expectRevert(Errors.ZeroAddress.selector);
        vault.setFeeRecipient(address(0));
    }

    /*
     * CURATOR ROLE TESTS
     */

    /**
     * @notice Test that curator can set minimum idle assets
     * @dev Verifies curator role has permission to update minimum idle assets percentage
     */
    function test_SetMinimumIdleAssets_AsCurator() public {
        uint256 newMinimum = 10_00; // 10%

        vm.prank(curator);
        vault.setMinimumIdleAssets(newMinimum);

        assertEq(vault.getMinimumIdleAssets(), newMinimum);
    }

    /**
     * @notice Test that manager cannot set minimum idle assets
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetMinimumIdleAssets_AsManager() public {
        uint256 newMinimum = 10_00;

        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, CURATOR_ROLE)
        );
        vault.setMinimumIdleAssets(newMinimum);
    }

    /**
     * @notice Test that allocator cannot set minimum idle assets
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetMinimumIdleAssets_AsAllocator() public {
        uint256 newMinimum = 10_00;

        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, CURATOR_ROLE)
        );
        vault.setMinimumIdleAssets(newMinimum);
    }

    /**
     * @notice Test that unauthorized user cannot set minimum idle assets
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_SetMinimumIdleAssets_AsUnauthorizedUser() public {
        uint256 newMinimum = 10_00;

        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, CURATOR_ROLE)
        );
        vault.setMinimumIdleAssets(newMinimum);
    }

    /**
     * @notice Test that curator can add new strategy
     * @dev Verifies curator role has permission to add strategies with allocations
     */
    function test_AddStrategy_AsCurator() public {
        uint256 allocation = 50_00; // 50%

        vm.prank(curator);
        vault.addStrategy(address(strategy), allocation);

        assertEq(vault.getStrategyIndex(address(strategy)), 0);
        assertEq(vault.getTotalStrategies(), 1);
    }

    /**
     * @notice Test that manager cannot add strategy
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_AddStrategy_AsManager() public {
        uint256 allocation = 50_00;

        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, CURATOR_ROLE)
        );
        vault.addStrategy(address(strategy), allocation);
    }

    /**
     * @notice Test that allocator cannot add strategy
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_AddStrategy_AsAllocator() public {
        uint256 allocation = 50_00;

        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, CURATOR_ROLE)
        );
        vault.addStrategy(address(strategy), allocation);
    }

    /**
     * @notice Test that unauthorized user cannot add strategy
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_AddStrategy_AsUnauthorizedUser() public {
        uint256 allocation = 50_00;

        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, CURATOR_ROLE)
        );
        vault.addStrategy(address(strategy), allocation);
    }

    /**
     * @notice Test that curator can remove strategy
     * @dev Verifies curator can add and then remove a strategy
     */
    function test_RemoveStrategy_AsCurator() public {
        // First add a strategy
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Then remove it
        vm.prank(curator);
        vault.removeStrategy(address(strategy));

        assertEq(vault.getTotalStrategies(), 0);
    }

    /**
     * @notice Test that manager cannot remove strategy
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_RemoveStrategy_AsManager() public {
        // First add a strategy as curator
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to remove as manager
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, CURATOR_ROLE)
        );
        vault.removeStrategy(address(strategy));
    }

    /**
     * @notice Test that allocator cannot remove strategy
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_RemoveStrategy_AsAllocator() public {
        // First add a strategy as curator
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to remove as allocator
        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, CURATOR_ROLE)
        );
        vault.removeStrategy(address(strategy));
    }

    /**
     * @notice Test that unauthorized user cannot remove strategy
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_RemoveStrategy_AsUnauthorizedUser() public {
        // First add a strategy as curator
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to remove as unauthorized user
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, CURATOR_ROLE)
        );
        vault.removeStrategy(address(strategy));
    }

    /*
     * ALLOCATOR ROLE TESTS
     */

    /**
     * @notice Test that allocator can change strategy allocation
     * @dev Verifies allocator role has permission to modify strategy allocations
     */
    function test_ChangeStrategyAllocation_AsAllocator() public {
        // First add strategies as curator
        vm.startPrank(curator);
        vault.addStrategy(address(strategy), 50_00);
        vault.addStrategy(address(strategy2), 30_00);
        vm.stopPrank();

        // Change allocation as allocator
        uint256 newAllocation = 60_00;
        vm.prank(allocator);
        vault.changeStrategyAllocation(address(strategy), newAllocation);

        assertEq(vault.getStrategyDetails(0).allocation, newAllocation);
    }

    /**
     * @notice Test that manager cannot change strategy allocation
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_ChangeStrategyAllocation_AsManager() public {
        // First add a strategy as curator
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to change allocation as manager
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, ALLOCATOR_ROLE)
        );
        vault.changeStrategyAllocation(address(strategy), 60_00);
    }

    /**
     * @notice Test that curator cannot change strategy allocation
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_ChangeStrategyAllocation_AsCurator() public {
        // First add a strategy as curator
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to change allocation as curator
        vm.prank(curator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, curator, ALLOCATOR_ROLE)
        );
        vault.changeStrategyAllocation(address(strategy), 60_00);
    }

    /**
     * @notice Test that unauthorized user cannot change strategy allocation
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_ChangeStrategyAllocation_AsUnauthorizedUser() public {
        // First add a strategy as curator
        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to change allocation as unauthorized user
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, ALLOCATOR_ROLE
            )
        );
        vault.changeStrategyAllocation(address(strategy), 60_00);
    }

    /**
     * @notice Test that allocator can reallocate funds
     * @dev Verifies allocator can trigger fund reallocation after deposits
     */
    function test_ReallocateFunds_AsAllocator() public {
        // Setup: deposit funds and add strategy
        _deposit(DEPOSIT_AMOUNT);

        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Reallocate as allocator
        vm.prank(allocator);
        vault.reallocateFunds();

        // Verify funds were reallocated (no revert means success)
        assertTrue(vault.getAssetInStrategy(address(strategy)) > 0);
    }

    /**
     * @notice Test that manager cannot reallocate funds
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_ReallocateFunds_AsManager() public {
        // Setup: deposit funds and add strategy
        _deposit(DEPOSIT_AMOUNT);

        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to reallocate as manager
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, ALLOCATOR_ROLE)
        );
        vault.reallocateFunds();
    }

    /**
     * @notice Test that curator cannot reallocate funds
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_ReallocateFunds_AsCurator() public {
        // Setup: deposit funds and add strategy
        _deposit(DEPOSIT_AMOUNT);

        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to reallocate as curator
        vm.prank(curator);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, curator, ALLOCATOR_ROLE)
        );
        vault.reallocateFunds();
    }

    /**
     * @notice Test that unauthorized user cannot reallocate funds
     * @dev Expects revert with AccessControlUnauthorizedAccount error
     */
    function test_RevertWhen_ReallocateFunds_AsUnauthorizedUser() public {
        // Setup: deposit funds and add strategy
        _deposit(DEPOSIT_AMOUNT);

        vm.prank(curator);
        vault.addStrategy(address(strategy), 50_00);

        // Try to reallocate as unauthorized user
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, ALLOCATOR_ROLE
            )
        );
        vault.reallocateFunds();
    }

    /*
     * ROLE MANAGEMENT TESTS
     */

    /**
     * @notice Test that admin can grant roles
     * @dev Verifies DEFAULT_ADMIN_ROLE can grant any role and grantee can execute protected functions
     */
    function test_GrantRole_AsAdmin() public {
        address newManager = makeAddr("NEW_MANAGER");

        // Admin (deployer) grants manager role
        vault.grantRole(MANAGER_ROLE, newManager);

        assertTrue(vault.hasRole(MANAGER_ROLE, newManager));

        // New manager can execute protected function
        vm.prank(newManager);
        vault.setEntryFee(100);
        assertEq(vault.getEntryFee(), 100);
    }

    /**
     * @notice Test that admin can revoke roles
     * @dev Verifies DEFAULT_ADMIN_ROLE can revoke roles and revoked addresses lose access
     */
    function test_RevokeRole_AsAdmin() public {
        // Admin revokes existing manager's role
        vault.revokeRole(MANAGER_ROLE, manager);

        assertFalse(vault.hasRole(MANAGER_ROLE, manager));

        // Manager can no longer execute protected function
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, MANAGER_ROLE)
        );
        vault.setEntryFee(100);
    }

    /**
     * @notice Test that account can renounce their own role
     * @dev Verifies self-renunciation works and access is lost after renouncing
     */
    function test_RenounceRole() public {
        // Manager renounces their own role
        vm.prank(manager);
        vault.renounceRole(MANAGER_ROLE, manager);

        assertFalse(vault.hasRole(MANAGER_ROLE, manager));

        // Can no longer execute protected functions
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, manager, MANAGER_ROLE)
        );
        vault.setEntryFee(100);
    }

    /**
     * @notice Test that account cannot renounce role for another account
     * @dev Expects revert with AccessControlBadConfirmation error
     */
    function test_RevertWhen_RenounceRole_ForOtherAccount() public {
        // Manager tries to renounce curator's role (should fail)
        vm.prank(manager);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlBadConfirmation.selector));
        vault.renounceRole(CURATOR_ROLE, curator);
    }

    /**
     * @notice Test that single address can have multiple roles
     * @dev Verifies an address can hold MANAGER, CURATOR, and ALLOCATOR roles simultaneously
     */
    function test_MultipleRolesOnSameAddress() public {
        address multiRole = makeAddr("MULTI_ROLE");

        // Grant multiple roles to same address
        vault.grantRole(MANAGER_ROLE, multiRole);
        vault.grantRole(CURATOR_ROLE, multiRole);
        vault.grantRole(ALLOCATOR_ROLE, multiRole);

        // Verify all roles are granted
        assertTrue(vault.hasRole(MANAGER_ROLE, multiRole));
        assertTrue(vault.hasRole(CURATOR_ROLE, multiRole));
        assertTrue(vault.hasRole(ALLOCATOR_ROLE, multiRole));

        // Test can execute functions from all roles
        vm.startPrank(multiRole);

        // Manager function
        vault.setEntryFee(100);
        assertEq(vault.getEntryFee(), 100);

        // Curator function
        vault.addStrategy(address(strategy), 50_00);
        assertEq(vault.getTotalStrategies(), 1);

        // Allocator function (need to deposit first)
        vm.stopPrank();
        _deposit(DEPOSIT_AMOUNT);
        vm.prank(multiRole);
        vault.reallocateFunds();

        assertTrue(vault.getAssetInStrategy(address(strategy)) > 0);
    }

    /**
     * @notice Test role admin hierarchy
     * @dev Verifies all roles have DEFAULT_ADMIN_ROLE as their admin
     */
    function test_GetRoleAdmin() public view {
        // All roles should have DEFAULT_ADMIN_ROLE as admin
        assertEq(vault.getRoleAdmin(MANAGER_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(vault.getRoleAdmin(CURATOR_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(vault.getRoleAdmin(ALLOCATOR_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(vault.getRoleAdmin(DEFAULT_ADMIN_ROLE), DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice Test that default admin can grant all roles including admin
     * @dev Verifies DEFAULT_ADMIN_ROLE can grant any role including itself
     */
    function test_DefaultAdminCanGrantAllRoles() public {
        address newAccount = makeAddr("NEW_ACCOUNT");

        // As default admin (deployer), grant all roles
        vault.grantRole(MANAGER_ROLE, newAccount);
        vault.grantRole(CURATOR_ROLE, newAccount);
        vault.grantRole(ALLOCATOR_ROLE, newAccount);
        vault.grantRole(DEFAULT_ADMIN_ROLE, newAccount);

        // Verify all roles were granted
        assertTrue(vault.hasRole(MANAGER_ROLE, newAccount));
        assertTrue(vault.hasRole(CURATOR_ROLE, newAccount));
        assertTrue(vault.hasRole(ALLOCATOR_ROLE, newAccount));
        assertTrue(vault.hasRole(DEFAULT_ADMIN_ROLE, newAccount));
    }

    /**
     * @notice Test that non-admin roles cannot grant roles
     * @dev Verifies MANAGER, CURATOR, and ALLOCATOR cannot grant any roles
     */
    function test_NonAdminCannotGrantRoles() public {
        address newAccount = makeAddr("NEW_ACCOUNT");

        // Manager cannot grant manager role
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, manager, DEFAULT_ADMIN_ROLE
            )
        );
        vault.grantRole(MANAGER_ROLE, newAccount);

        // Curator cannot grant curator role
        vm.prank(curator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, curator, DEFAULT_ADMIN_ROLE
            )
        );
        vault.grantRole(CURATOR_ROLE, newAccount);

        // Allocator cannot grant allocator role
        vm.prank(allocator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, allocator, DEFAULT_ADMIN_ROLE
            )
        );
        vault.grantRole(ALLOCATOR_ROLE, newAccount);
    }

    /*
     * HELPER FUNCTIONS
     */

    /**
     * @notice Helper function to deposit assets into vault
     * @dev Approves and deposits USDC as test user
     * @param depositAmount Amount of USDC to deposit
     */
    function _deposit(uint256 depositAmount) internal {
        vm.startPrank(user);
        ERC20(networkConfig.usdc).approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
    }
}
