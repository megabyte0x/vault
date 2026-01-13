// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SimpleVTS} from "../../src/SimpleVTS.sol";

/// @title SimpleVTSHarness
/// @notice Test harness for SimpleVTS contract that exposes internal functions for testing
/// @dev Extends SimpleVTS to make internal functions public for unit testing purposes
/// @author megabyte0x.eth
contract SimpleVTSHarness is SimpleVTS {
    /// @notice Initializes the harness with the same parameters as SimpleVTS
    /// @param _asset The address of the underlying asset
    /// @param _admin The address of the admin who receives DEFAULT_ADMIN_ROLE
    constructor(address _asset, address _admin) SimpleVTS(_asset, _admin) {}

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
