// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SimpleVault} from "../../src/SimpleVault.sol";

/// @title SimpleVaultHarness
/// @notice Test harness for SimpleVault contract that exposes internal functions for testing
/// @dev Extends SimpleVault to make internal functions public for unit testing purposes
/// @author megabyte0x.eth
contract SimpleVaultHarness is SimpleVault {
    /// @notice Initializes the harness with the underlying asset
    /// @param _asset The address of the underlying ERC20 asset
    constructor(address _asset) SimpleVault(_asset) {}

    /// @notice Exposes the internal _underlyingDecimals function for testing
    /// @return The number of decimals used by the underlying asset
    function underlyingDecimals() external view returns (uint8) {
        return _underlyingDecimals();
    }

    /// @notice Exposes the internal _feeOnRaw function for testing fee calculations
    /// @param assets The base amount of assets (without fees)
    /// @param feeBasisPoints The fee rate in basis points
    /// @return The calculated fee amount that should be added to assets
    function feeOnRaw(uint256 assets, uint256 feeBasisPoints) external pure returns (uint256) {
        return _feeOnRaw(assets, feeBasisPoints);
    }

    /// @notice Exposes the internal _feeOnTotal function for testing fee calculations
    /// @param assets The total amount of assets (including fees)
    /// @param feeOnBasisPoints The fee rate in basis points
    /// @return The calculated fee portion of the total assets
    function feeOnTotal(uint256 assets, uint256 feeOnBasisPoints) external pure returns (uint256) {
        return _feeOnTotal(assets, feeOnBasisPoints);
    }
}
