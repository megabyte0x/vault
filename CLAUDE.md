# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ERC-4626 vault implementation that integrates with DeFi protocols (Aave and Morpho). The vault accepts ERC20 tokens and issues shares, deploying 80% of deposited assets equally between Aave Pool and Morpho Vault through a strategy contract.

## Key Commands

### Building and Testing
```bash
# Build contracts
make build
# or
forge build

# Run all tests (requires mainnet fork)
make test
# or
forge test --fork-url mainnet --block-number ${BLOCK_NUMBER} --etherscan-api-key etherscan_api_key

# Run specific deposit test with verbose output
make testDeposit

# Format code
make format
# or
forge fmt

# Generate gas report
make gasReport

# Generate coverage report
make coverage
make coverageLCOV
```

### Development Environment
```bash
# Start local anvil node
make anvil

# Deploy SimpleVault to Tenderly network (uses environment variables securely)
make deploySimpleVault
```

### Dependencies
```bash
# Install all dependencies
make install

# Update dependencies
make update

# Clean build artifacts
make clean
```

## Architecture

### Core Contracts

**SimpleVault** (`src/SimpleVault.sol`):
- ERC-4626 compliant vault contract extending Solady's ERC4626
- Manages entry/exit fees (configurable in basis points)
- Integrates with SimpleStrategy for yield generation
- Handles fee distribution to designated recipient

**SimpleStrategy** (`src/SimpleStrategy.sol`):
- Implements yield strategy by splitting 80% of deposits equally between:
  - Aave Pool (40% of total deposit)
  - Morpho Vault (40% of total deposit)
- Remaining 20% stays in vault as reserve/liquidity
- Uses OpenZeppelin's Address library for safe contract calls

### Dependencies and Imports

The project uses several key libraries via remappings:
- `@solady` - Gas-optimized Solidity utilities (ERC4626, FixedPointMathLib, SafeTransferLib)
- `@openzeppelin` - Battle-tested smart contract standards
- `@morpho` - Morpho protocol integration via vault-v2 submodule
- `@devops` - Foundry DevOps tools for deployment

### Configuration Structure

**Network Configuration** (`script/HelperConfig.s.sol`):
- Mainnet addresses for USDC, Morpho Vault, and Aave Pool
- Default fee structure: 0.05% entry fee, 0.1% exit fee
- Whale address for testing token transfers

### Testing Setup

Tests are located in `test/unit/` and use Foundry's testing framework with mainnet forking:
- Fork-based testing against live DeFi protocols
- USDC minting for test scenarios (100M USDC test amount)
- Integration with HelperConfig for network-specific addresses

## Environment Requirements

- Mainnet RPC URL for fork testing
- Etherscan API key for contract verification
- Tenderly access key and RPC for deployment to Tenderly Virtual TestNet
- Environment variables defined in `.env` file

## Development Workflow

1. Use `make test` to run the full test suite with mainnet fork
2. Individual test functions can be run with `forge test --mt <test_name>`
3. Always run `make format` before committing
4. Use `make build` to verify compilation
5. Deploy to Tenderly using `make deploySimpleVault` for testing

The project follows a modular architecture where the vault delegates yield generation to a pluggable strategy contract, allowing for future strategy implementations while maintaining the core vault functionality.