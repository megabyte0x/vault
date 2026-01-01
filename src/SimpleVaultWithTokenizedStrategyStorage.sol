// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DataTypes} from "./lib/DataTypes.sol";
import {Errors} from "./lib/Errors.sol";

contract SimpleVaultWithTokenizedStrategyStorage {
    /**
     * @notice Emitted when the entry fee is updated
     * @param newEntryFee The new entry fee in basis points
     */
    event SimpleVault__EntryFeeUpdated(uint256 indexed newEntryFee);

    /// @notice Emitted when the exit fee is updated
    /// @param newExitFee The new exit fee in basis points
    event SimpleVault__ExitFeeUpdated(uint256 indexed newExitFee);

    /// @notice Emitted when the fee recipient address is updated
    /// @param newFeeRecipient The new address that will receive fees
    event SimpleVault__FeeRecipientUpdated(address indexed newFeeRecipient);

    /// @notice Emitted when the strategy contract is updated
    /// @param newStrategy The new strategy contract address
    event SimpleVault__StrategyUpdated(address indexed newStrategy);

    event SimpleVault__TokenizedStrategyAdded(address indexed strategy, uint256 indexed allocation);

    event SimpleVault__TokenizedStrategyRemoved(address indexed strategy);

    event SimpleVault__AllocationUpdated(address indexed strategy, uint256 indexed newAllocation);

    event SimpleVault__FundsReallocated();

    event SimpleVault__MinimumIdleAssetsUpdated(uint256 indexed newMinimumIdleAssets);

    /// @notice The underlying asset that the vault accepts (immutable)
    address internal immutable i_asset;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    /// @notice Max number of strategies.
    uint256 internal constant MAX_STRATEGIES = 10;

    bytes32 public constant ALLOCATOR = keccak256("ALLOCATOR");
    bytes32 public constant CURATOR = keccak256("CURATOR");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    DataTypes.VaultState internal s_vault;

    /// @notice State of the strategies.
    DataTypes.StrategyState internal s_strategy;

    constructor(address asset_) {
        if (asset_ == address(0)) revert Errors.ZeroAddress();
        i_asset = asset_;
    }
}
