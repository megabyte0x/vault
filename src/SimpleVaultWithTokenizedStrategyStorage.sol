// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {DataTypes} from "./libraries/DataTypes.sol";
import {Errors} from "./libraries/Errors.sol";

contract SimpleVaultWithTokenizedStrategyStorage {
    /**
     * @notice Emitted when the entry fee is updated
     * @param newEntryFee The new entry fee in basis points
     */
    event SimpleVault__EntryFeeUpdated(uint256 newEntryFee);

    /// @notice Emitted when the exit fee is updated
    /// @param newExitFee The new exit fee in basis points
    event SimpleVault__ExitFeeUpdated(uint256 newExitFee);

    /// @notice Emitted when the fee recipient address is updated
    /// @param newFeeRecipient The new address that will receive fees
    event SimpleVault__FeeRecipientUpdated(address newFeeRecipient);

    /// @notice Emitted when the strategy contract is updated
    /// @param newStrategy The new strategy contract address
    event SimpleVault__StrategyUpdated(address newStrategy);

    event SimpleVault__TokenizedStrategyAdded(address strategy, uint256 allocation);

    event SimpleVault__TokenizedStrategyRemoved(address strategy);

    /// @notice The underlying asset that the vault accepts (immutable)
    address internal immutable i_asset;

    /// @notice Scale factor for basis points calculations (10,000 = 100%)
    uint256 internal constant BASIS_POINT_SCALE = 1e4;

    uint256 internal constant MAX_STRATEGIES = 10;

    /// @notice Entry fee charged on deposits, expressed in basis points
    uint256 internal s_entryFee;

    /// @notice Exit fee charged on withdrawals, expressed in basis points
    uint256 internal s_exitFee;

    /// @notice Address that receives collected fees
    address internal s_feeRecipient;

    DataTypes.State internal s_state;

    constructor(address asset_) {
        if (asset_ == address(0)) revert Errors.ZeroAddress();
        i_asset = asset_;
    }
}
