// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Address} from "@openzeppelin/utils/Address.sol";
import {IVaultV2 as IMorpho} from "@morpho/interfaces/IVaultV2.sol";

import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";

/**
 * @title SimpleTokenizedStrategy
 * @author megabyte0x.eth
 * @notice Inspired from Yearn's Tokenized Strategy (https://github.com/yearn/tokenized-strategy/) this is a simple implementation of a tokenized strategy where strategy itself is a Vault and funds are deposited into single yield source and shares are allocated accordingly.
 * @dev In the strategy, our yield source is AAVE.
 */
abstract contract SimpleTokenizedStrategy is ERC4626 {
    using Address for address;

    address public immutable i_yieldSource;

    /// @notice The vault contract that owns this strategy
    address public immutable i_vault;

    constructor(address yieldSource_, address vault_) {
        i_yieldSource = yieldSource_;
        i_vault = vault_;
    }

    function asset() public view override returns (address assetAddress) {
        bytes memory data = i_vault.functionStaticCall(abi.encodeWithSignature("asset()"));

        assetAddress = abi.decode(data, (address));
    }

    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(asset()).decimals();
    }

    function totalAssets() public view virtual override returns (uint256 assets) {
        return 0;
    }
}
