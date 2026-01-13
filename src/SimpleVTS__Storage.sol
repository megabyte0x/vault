// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DataTypes} from "./lib/DataTypes.sol";
import {Errors} from "./lib/Errors.sol";

/// @title SimpleVTS__Storage
/// @notice Storage contract for SimpleVTS vault containing state variables and access control roles
/// @dev Separated storage contract pattern for upgradeable design and gas optimization
/// @author megabyte0x.eth
contract SimpleVTS__Storage {
    /// @notice The underlying asset that the vault accepts (immutable)
    address internal immutable i_asset;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    /// @notice Maximum number of strategies that can be added to the vault
    //! TODO: Consider making this configurable rather than hardcoded
    uint256 internal constant MAX_STRATEGIES = 10;

    /// @notice Role identifier for users who can reallocate funds and manage strategy queues
    bytes32 public constant ALLOCATOR = keccak256("ALLOCATOR");

    /// @notice Role identifier for users who can add new strategies to the vault
    bytes32 public constant CURATOR = keccak256("CURATOR");

    /// @notice Role identifier for users with full management privileges including emergency functions
    bytes32 public constant MANAGER = keccak256("MANAGER");

    /// @notice Vault configuration state including fees and recipient
    DataTypes.VaultState internal s_vault;

    /// @notice Complete strategy management state including strategies array and queues
    DataTypes.StrategyState internal s_strategy;

    /// @notice Initializes the storage contract with the underlying asset
    /// @param asset_ The address of the ERC20 token to be used as the underlying asset
    constructor(address asset_) {
        if (asset_ == address(0)) revert Errors.ZeroAddress();
        i_asset = asset_;
    }
}
