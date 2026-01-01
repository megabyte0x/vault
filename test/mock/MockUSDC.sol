// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC20} from "@solady/tokens/ERC20.sol";

contract MockUSDC is ERC20 {
    function name() public pure override returns (string memory) {
        return "mUSDC";
    }

    function symbol() public pure override returns (string memory) {
        return "mUSDC";
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
