// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library DataTypes {
    struct Allocation {
        uint256 index;
        uint256 amount;
    }

    struct Strategy {
        /// @notice Address of the Tokenized Strategy Vault.
        address strategy;
        /// @notice Maximum number of `assets` that can be deposited in this `Strategy`.
        uint256 cap;
    }

    struct StrategyState {
        /// @notice Total number of strategies currently vault is working with.
        uint256 totalStrategies;
        /// @notice Mapping from index to the strategy
        mapping(uint256 index => Strategy strategy) strategies;
        /// @notice Mapping from Strategy address to its index.
        /// @dev 0 means not present, otherwise index + 1.
        mapping(address strategy => uint256 indexPlusOne) strategyToIndex;

        uint256[] withdrawQueue;

        uint256[] supplyQueue;
    }

    struct VaultState {
        /// @notice Entry fee charged on deposits, expressed in basis points
        uint256 entryFee;
        /// @notice Exit fee charged on withdrawals, expressed in basis points
        uint256 exitFee;
        /// @notice Address that receives collected fees
        address feeRecipient;
    }
}
