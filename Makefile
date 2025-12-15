-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install Cyfrin/foundry-devops && forge install foundry-rs/forge-std && forge install OpenZeppelin/openzeppelin-contracts && forge install vectorized/solady

# Update Dependencies
update:; forge update

build:; forge build

FORK_NETWORK_ARGS := --fork-url mainnet --block-number $(BLOCK_NUMBER) --etherscan-api-key etherscan_api_key

TENDERLY_NETWORK_ARGS := --slow --rpc-url tenderly  --verify  --verifier-url $(TENDERLY_VERIFIER_URL) --etherscan-api-key $(TENDERLY_ACCESS_KEY) --broadcast

test :; forge test $(FORK_NETWORK_ARGS)

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

gasReport:
	forge test $(FORK_NETWORK_ARGS) --gas-report

coverage:
	forge coverage $(FORK_NETWORK_ARGS)

coverageLCOV:
	forge coverage $(FORK_NETWORK_ARGS) --report lcov

testDeposit: 
	forge test --mt test_deposit $(FORK_NETWORK_ARGS) -vvvv

testTotalSupply:
	forge test --mt test_totalSupply $(FORK_NETWORK_ARGS) -vvvv	

testWithdraw:
	forge test --mt test_withdraw $(FORK_NETWORK_ARGS) -vv

testFuzz:
	forge test --mt testFuzz $(FORK_NETWORK_ARGS) -vv	

deploySimpleVault:
	@forge script script/deploy/DeploySimpleVault.s.sol:DeploySimpleVault $(TENDERLY_NETWORK_ARGS)  --account dev

deploySimpleStrategy: 
	@forge script script/deploy/DeploySimpleStrategy.s.sol:DeploySimpleStrategy $(TENDERLY_NETWORK_ARGS) --account dev

initializeVault:
	@forge script script/interactions/SimpleVault.s.sol:SimpleVault__Initialize $(TENDERLY_NETWORK_ARGS) --account dev

setup: 
	make deploySimpleVault && make deploySimpleStrategy && make initializeVault

depositInVault:
	@forge script script/interactions/SimpleVault.s.sol:SimpleVault__Deposit $(TENDERLY_NETWORK_ARGS) --account dev

