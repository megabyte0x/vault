// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract MockYieldSource {
    function supply(address asset, uint256 amount) external {}
    function withdraw(address asset, uint256 amount) external {}
    function balanceOf(address user) external view returns (uint256) {}
}
