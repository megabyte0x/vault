// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ISimpleStrategy {
    function asset() external view returns (address);

    function supply(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function totalAssetsInVault() external view returns (uint256 balance);
}
