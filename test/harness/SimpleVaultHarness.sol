// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {SimpleVault} from "../../src/SimpleVault.sol";

contract SimpleVaultHarness is SimpleVault {
    constructor(address _asset) SimpleVault(_asset) {}

    function underlyingDecimals() external view returns (uint8) {
        return _underlyingDecimals();
    }

    function feeOnRaw(uint256 assets, uint256 feeBasisPoints) external pure returns (uint256) {
        return _feeOnRaw(assets, feeBasisPoints);
    }

    function feeOnTotal(uint256 assets, uint256 feeOnBasisPoints) external pure returns (uint256) {
        return _feeOnTotal(assets, feeOnBasisPoints);
    }
}
