// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract MockYieldSource {
    mapping(address user => mapping(address asset => uint256 balance)) balances;

    function supply(address asset, uint256 amount) external {
        balances[msg.sender][asset] += amount;
    }

    function withdraw(address asset, uint256 amount) external {
        balances[msg.sender][asset] -= amount;
    }

    function balanceOf(address asset, address user) external view returns (uint256) {
        return balances[user][asset];
    }
}
