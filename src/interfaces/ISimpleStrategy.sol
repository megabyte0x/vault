// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title ISimpleStrategy
/// @notice Interface for vault strategy contracts that manage yield generation
/// @dev Defines the standard functions that all strategy implementations must provide
/// @author megabyte0x.eth
interface ISimpleStrategy {
    /// @notice Returns the address of the underlying asset
    /// @return The address of the ERC20 token managed by this strategy
    function asset() external view returns (address);

    /// @notice Supplies assets to external protocols for yield generation
    /// @param amount The amount of assets to be deployed
    function supply(uint256 amount) external;

    /// @notice Withdraws assets from external protocols to meet withdrawal demands
    /// @param amount The amount of assets that need to be made available
    function withdraw(uint256 amount) external;

    /// @notice Withdraws all funds from external protocols back to the vault
    /// @dev Called when strategy is being replaced or vault needs full liquidity
    function withdrawFunds() external;

    /// @notice Returns the total assets under management across all positions
    /// @return balance The total amount of assets managed by this strategy
    function totalAssets() external view returns (uint256 balance);
}
