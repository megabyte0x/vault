# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ERC-4626 vault implementation with two main variants:
1. **SimpleVault**: Integrates with DeFi protocols (Aave and Morpho) through a single strategy
2. **SimpleVaultWithTokenizedStrategy**: Advanced vault with modular tokenized strategy support

Both vaults accept ERC20 tokens, issue shares, and deploy assets through configurable strategies. The tokenized strategy variant supports multiple strategies with custom allocations.

**Current Status**: Work in progress - SimpleVault core functionality is complete, tokenized strategy variant is actively being developed.

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

# Run specific test suites
make testDeposit         # Test deposit functionality
make testWithdraw        # Test withdrawal functionality
make testTotalSupply     # Test total supply calculations
make testFuzz           # Run fuzz tests (1000 runs configured)
make testVTS            # Run Vault with Tokenized Strategy tests

# Run individual test functions
forge test --mt <test_function_name> --fork-url mainnet --block-number ${BLOCK_NUMBER}

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

**SimpleVTS** (`src/SimpleVTS.sol`):
- Advanced ERC-4626 vault with modular tokenized strategy support (previously SimpleVaultWithTokenizedStrategy)
- Supports multiple strategies with configurable allocations
- Uses library-based architecture for gas optimization and modularity
- Implements AccessControl with multiple roles (MANAGER, CURATOR, ALLOCATOR)
- Includes ReentrancyGuard for secure operations
- Maintains minimum idle asset ratios for liquidity management
- Storage contract: `SimpleVTS__Storage.sol`

**SimpleStrategy** (`src/SimpleStrategy.sol`):
- Single-strategy implementation splitting 80% of deposits equally between:
  - Aave Pool (40% of total deposit)
  - Morpho Vault (40% of total deposit)
- Remaining 20% stays in vault as reserve/liquidity

**Tokenized Strategies** (`src/TokenizedStrategy/`):
- `SimpleTokenizedStrategy.sol`: Base tokenized strategy implementation
- `AaveTokenizedStrategy.sol`: Aave-specific tokenized strategy

### Library Architecture (SimpleVTS)

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
**Event Handling**: `Events.sol` - Centralized event definitions for strategy operations

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
  - `VTS.t.sol`: Tests for SimpleVTS (tokenized strategy vault)
  - `VTS/`: Specialized VTS tests
    - `AccessControl.t.sol`: Access control and role management tests
    - `AddStrategy.t.sol`: Strategy addition and management tests
  - `SimpleStrategy.t.sol`: Tests for strategy implementation
- `test/fuzz/`: Fuzz testing for edge cases
  - `SimpleVault.t.sol`: Fuzz tests for vault operations
- `test/harness/`: Test harnesses for internal function testing
  - `SimpleVTSHarness.sol`: Harness for SimpleVTS internal functions
  - `SimpleVaultHarness.sol`: Harness for SimpleVault internal functions
- `test/BaseTest.t.sol`: Base test contract for SimpleVault
- `test/BaseTestForVTS.t.sol`: Base test contract for tokenized strategy vault
- Mock contracts in `test/mock/`:
  - `MockTokenizedStrategy.sol`: Mock strategy for testing
  - `MockUSDC.sol`: Mock USDC token for testing
  - `MockYieldSource.sol`: Mock yield source for testing

**Fork Configuration**:
- Fork-based testing against live DeFi protocols
- USDC minting for test scenarios (100M USDC test amount)
- Integration with HelperConfig for network-specific addresses
- Environment variable `BLOCK_NUMBER` for consistent fork state
- Fuzz test runs: 1000 (configured in foundry.toml)

## Environment Requirements

Required environment variables in `.env` file:
- `MAINNET_RPC_URL`: Mainnet RPC endpoint for fork testing
- `ETHERSCAN_KEY`: Etherscan API key for contract verification
- `BLOCK_NUMBER`: Block number for consistent mainnet fork state
- `TENDERLY_ACCESS_KEY`: Tenderly access key for deployment
- `TENDERLY_VIRTUAL_TESTNET_RPC`: Tenderly Virtual TestNet RPC URL
- `TENDERLY_VERIFIER_URL`: Tenderly verifier URL for contract verification

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
**SimpleVTS**: Library-based modular pattern supporting:
- Multiple tokenized strategies with dynamic allocations
- Gas-optimized operations through library delegation
- Role-based access control with multiple roles (MANAGER, CURATOR, ALLOCATOR)
- Reentrancy protection for secure operations
- Supply and withdraw queue management for optimal strategy allocation
- Minimum idle asset management for liquidity requirements

Both architectures allow pluggable strategy contracts for future protocol integrations while maintaining ERC-4626 compliance.

## Security Considerations

The project includes security auditing documentation (`basic_audit.md`) that highlights critical areas requiring attention:
- Access control validation for all role-based functions
- Array bounds checking in queue management
- Reentrancy protection on deposit/withdraw operations
- Integer overflow/underflow protection in calculations

Developers should review audit findings before making changes to critical functions.