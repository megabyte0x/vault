// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title DataTypes
/// @notice Core data structures used throughout the SimpleVTS vault system
/// @dev Centralizes struct definitions for consistent usage across contracts and libraries
/// @author megabyte0x.eth
library DataTypes {
    /// @notice Represents an allocation instruction for fund reallocation
    /// @dev Used in reallocateFunds to specify which strategy and how much to allocate
    struct Allocation {
        /// @notice Index of the strategy in the strategies array
        uint256 index;
        /// @notice Amount of assets to allocate to this strategy
        uint256 amount;
    }

    /// @notice Represents a single tokenized strategy and its constraints
    /// @dev Contains strategy address and allocation cap for risk management
    struct Strategy {
        /// @notice Address of the tokenized strategy vault contract
        address strategy;
        /// @notice Maximum number of assets that can be deposited in this strategy
        uint256 cap;
    }

    /// @notice Complete state management for all strategies in the vault
    /// @dev Contains strategy storage, indexing, and queue management
    struct StrategyState {
        /// @notice Total number of strategies currently managed by the vault
        uint256 totalStrategies;
        /// @notice Mapping from index to strategy details
        mapping(uint256 index => Strategy strategy) strategies;
        /// @notice Mapping from strategy address to its index (plus one for existence check)
        /// @dev 0 means strategy not present, otherwise stores index + 1
        mapping(address strategy => uint256 indexPlusOne) strategyToIndex;
        /// @notice Array defining the order for withdrawing funds from strategies
        /// @dev Contains strategy indices, priority order for withdrawals
        uint256[] withdrawQueue;
        /// @notice Array defining the order for supplying funds to strategies
        /// @dev Contains strategy indices, priority order for deposits
        uint256[] supplyQueue;
    }

    /// @notice Configuration state for vault fee management
    /// @dev Contains fee rates and recipient address for vault operations
    struct VaultState {
        /// @notice Entry fee charged on deposits, expressed in basis points (e.g., 50 = 0.5%)
        uint256 entryFee;
        /// @notice Exit fee charged on withdrawals, expressed in basis points (e.g., 100 = 1%)
        uint256 exitFee;
        /// @notice Address that receives collected entry and exit fees
        address feeRecipient;

        /// @notice Maximum number of strategies that can be added to the vault
        uint256 maxStrategies;
    }
}
