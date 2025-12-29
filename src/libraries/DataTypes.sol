// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

library DataTypes {
    struct Strategy {
        address strategy;
        uint256 allocation;
    }

    struct State {
        uint256 totalStrategies;
        mapping(uint256 => Strategy) strategies;
        /// @dev 0 means not present, otherwise index + 1.
        mapping(address => uint256) strategyToIndex;
    }
}
