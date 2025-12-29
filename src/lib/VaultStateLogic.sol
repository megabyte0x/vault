// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DataTypes} from "./DataTypes.sol";

library VaultStateLogic {
    /**
     * Updates the entry fee.
     * @param s Current Vault State
     * @param newEntryFee New Entry Fee.
     */
    function updateEntryFee(DataTypes.VaultState storage s, uint256 newEntryFee) internal {
        s.entryFee = newEntryFee;
    }

    /**
     * Updates the exit fee.
     * @param s Current Vault State
     * @param newExitFee New Exit Fee.
     */
    function updateExitFee(DataTypes.VaultState storage s, uint256 newExitFee) internal {
        s.exitFee = newExitFee;
    }

    /**
     * Updates the fee recipient.
     * @param s Current Vault State
     * @param newFeeRecipient New Fee Recipient
     */
    function updateFeeRecipient(DataTypes.VaultState storage s, address newFeeRecipient) internal {
        s.feeRecipient = newFeeRecipient;
    }
}
