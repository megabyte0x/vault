# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ERC-4626 vault implementation with two main variants:
1. **SimpleVault**: Integrates with DeFi protocols (Aave and Morpho) through a single strategy
2. **SimpleVaultWithTokenizedStrategy**: Advanced vault with modular tokenized strategy support

Both vaults accept ERC20 tokens, issue shares, and deploy assets through configurable strategies. The tokenized strategy variant supports multiple strategies with custom allocations.

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

# Run specific tests with verbose output
make testDeposit         # Test deposit functionality
make testWithdraw        # Test withdrawal functionality
make testTotalSupply     # Test total supply calculations
make testFuzz           # Run fuzz tests
make testVTS            # Run Vault with Tokenized Strategy tests

# Format code
make format
# or
forge fmt

# Generate gas report
make gasReport

# Generate coverage reports
make coverage           # Basic coverage
make coverageTxt       # Coverage to text file
make coverageHTML      # Coverage with HTML report
```

### Development Environment
```bash
# Start local anvil node
make anvil

# Deploy contracts to Tenderly network (uses environment variables securely)
make deploySimpleVault      # Deploy SimpleVault
make deploySimpleStrategy   # Deploy SimpleStrategy
make initializeVault       # Initialize vault after deployment
make setup                 # Deploy and initialize everything
make depositInVault        # Interact with deployed vault
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
- Basic ERC-4626 compliant vault extending Solady's ERC4626
- Manages entry/exit fees (configurable in basis points)
- Integrates with SimpleStrategy for yield generation
- Handles fee distribution to designated recipient

**SimpleVaultWithTokenizedStrategy** (`src/SimpleVaultWithTokenizedStrategy.sol`):
- Advanced ERC-4626 vault with modular tokenized strategy support
- Supports multiple strategies with configurable allocations
- Uses library-based architecture for gas optimization and modularity
- Implements AccessControl for role-based permissions (MANAGER role)
- Maintains minimum idle asset ratios for liquidity management

**SimpleStrategy** (`src/SimpleStrategy.sol`):
- Single-strategy implementation splitting 80% of deposits equally between:
  - Aave Pool (40% of total deposit)
  - Morpho Vault (40% of total deposit)
- Remaining 20% stays in vault as reserve/liquidity

### Library Architecture (SimpleVaultWithTokenizedStrategy)

The tokenized strategy vault uses a modular library-based design in `src/lib/`:

**DataTypes.sol**: Core data structures
- `Strategy`: Individual strategy with address and allocation
- `StrategyState`: Complete strategy management state
- `VaultState`: Vault configuration (fees, recipient)

**Logic Libraries**:
- `StrategyStateLogic.sol`: Strategy management operations
- `VaultStateLogic.sol`: Vault configuration operations
- `TokenizedStrategyLogic.sol`: Strategy interaction logic
- `Helpers.sol`: Utility functions for validation and calculations

**Error Handling**: `Errors.sol` - Centralized custom error definitions

### Dependencies and Imports

The project uses several key libraries via remappings:
- `@solady` - Gas-optimized Solidity utilities (ERC4626, FixedPointMathLib, SafeTransferLib)
- `@openzeppelin` - Battle-tested smart contract standards (AccessControl)
- `@morpho` - Morpho protocol integration via vault-v2 submodule
- `@devops` - Foundry DevOps tools for deployment

### Configuration Structure

**Network Configuration** (`script/HelperConfig.s.sol`):
- Mainnet addresses for USDC, Morpho Vault, and Aave Pool
- Default fee structure: 0.05% entry fee, 0.1% exit fee
- Whale address for testing token transfers

### Testing Setup

Tests use Foundry's testing framework with mainnet forking:

**Test Structure**:
- `test/unit/`: Unit tests for individual contracts
  - `SimpleVault.t.sol`: Tests for basic vault functionality
  - `SimpleVaultWithTokenizedStrategy.t.sol`: Tests for advanced vault
  - `SimpleStrategy.t.sol`: Tests for strategy implementation
- `test/fuzz/`: Fuzz testing for edge cases
- `test/BaseTest.t.sol`: Base test contract for SimpleVault
- `test/BaseTestForVTS.t.sol`: Base test contract for tokenized strategy vault

**Fork Configuration**:
- Fork-based testing against live DeFi protocols
- USDC minting for test scenarios (100M USDC test amount)
- Integration with HelperConfig for network-specific addresses
- Environment variable `BLOCK_NUMBER` for consistent fork state

## Environment Requirements

- Mainnet RPC URL for fork testing
- Etherscan API key for contract verification
- Tenderly access key and RPC for deployment to Tenderly Virtual TestNet
- Environment variables defined in `.env` file

## Development Workflow

1. **Testing**: Use `make test` to run the full test suite with mainnet fork
2. **Individual Tests**: Run specific tests with `forge test --mt <test_name>` or use dedicated make targets
3. **Formatting**: Always run `make format` before committing
4. **Building**: Use `make build` to verify compilation
5. **Deployment**: Deploy to Tenderly using `make deploySimpleVault` or `make setup` for full deployment
6. **Coverage**: Generate coverage reports with `make coverageHTML` for detailed analysis

## Architecture Patterns

The project follows a modular architecture:

**SimpleVault**: Direct strategy integration pattern for simple use cases
**SimpleVaultWithTokenizedStrategy**: Library-based modular pattern supporting:
- Multiple tokenized strategies with dynamic allocations
- Gas-optimized operations through library delegation
- Role-based access control with MANAGER permissions
- Minimum idle asset management for liquidity requirements

Both architectures allow pluggable strategy contracts for future protocol integrations while maintaining ERC-4626 compliance.