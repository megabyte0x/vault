# Vault

> ⚠️ ️**WORK IN PROGRESS** ⚠️

This is a minimal implementation of a [ERC-4626](https://eips.ethereum.org/EIPS/eip-4626)(Vault).

This SimpleVault accepts an ERC20 token and issues shares with respect to it.

80% of the deposited token is split equally and supplied between Aave Pool and Morpho Vault.

Reference: 

- [RareSkills 4626 Blog](https://rareskills.io/post/erc4626)
- [Solady](https://github.com/Vectorized/solady)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/5.x/erc4626)
