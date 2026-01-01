// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {ERC20} from "@solady/tokens/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() {
        // Mint a large supply to the contract deployer for testing
        _mint(msg.sender, 1_000_000_000e6); // 1 billion USDC
    }

    function name() public pure override returns (string memory) {
        return "mUSDC";
    }

    function symbol() public pure override returns (string memory) {
        return "mUSDC";
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
