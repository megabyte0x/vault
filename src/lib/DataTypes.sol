// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library DataTypes {
    struct Strategy {
        /// @notice Address of the Tokenized Strategy Vault.
        address strategy;
        /// @notice Percentage of total assets to be allocated to this strategy, expressed in basis points.
        uint256 allocation;
    }

    struct StrategyState {
        /// @notice Percentage of minimum Idle assets needs to be present in the vault at all times, expressed in basis points.
        uint256 minimumIdleAssets;
        /// @notice Total number of strategies currently vault is working with.
        uint256 totalStrategies;
        /// @notice Mapping from index to the strategy
        mapping(uint256 index => Strategy strategy) strategies;
        /// @notice Mapping from Strategy address to its index.
        /// @dev 0 means not present, otherwise index + 1.
        mapping(address strategy => uint256 indexPlusOne) strategyToIndex;
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
