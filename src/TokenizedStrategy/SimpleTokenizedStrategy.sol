// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Address} from "@openzeppelin/utils/Address.sol";
import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";

/// @title SimpleTokenizedStrategy
/// @notice Abstract base contract for tokenized strategies that act as ERC-4626 vaults
/// @dev Inspired by Yearn's Tokenized Strategy architecture. Strategy itself is a vault that deposits into yield sources
/// @custom:security Ensures compatibility with vault's asset through immutable asset address
/// @author megabyte0x.eth
abstract contract SimpleTokenizedStrategy is ERC4626 {
    using Address for address;

    /// @notice The yield-generating protocol or contract address (e.g., Aave pool, Morpho vault)
    address public immutable i_yieldSource;

    /// @notice The vault contract that owns and manages this strategy
    address public immutable i_vault;

    /// @notice The underlying asset that this strategy accepts and manages
    address private immutable i_asset;

    /// @notice Initializes the tokenized strategy with yield source and vault
    /// @dev Automatically queries vault for asset address to ensure compatibility
    /// @param yieldSource_ The address of the yield-generating protocol
    /// @param vault_ The address of the vault that will manage this strategy
    constructor(address yieldSource_, address vault_) {
        i_yieldSource = yieldSource_;
        i_vault = vault_;

        // Query vault for its underlying asset to ensure compatibility
        bytes memory data = i_vault.functionStaticCall(abi.encodeWithSignature("asset()"));

        i_asset = abi.decode(data, (address));
    }

    /// @notice Returns the underlying asset managed by this strategy
    /// @inheritdoc ERC4626
    /// @return assetAddress The address of the underlying ERC20 token
    function asset() public view override returns (address assetAddress) {
        return i_asset;
    }

    /// @notice Returns the number of decimals used by the underlying asset
    /// @inheritdoc ERC4626
    /// @dev Used internally for precise share calculations
    /// @return The number of decimals of the underlying asset
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(asset()).decimals();
    }

    /// @notice Returns the total amount of assets under management by this strategy
    /// @inheritdoc ERC4626
    /// @dev Must be implemented by derived contracts to return actual deployed assets
    //! TODO: This should be implemented by derived contracts with actual balance calculation
    /// @return assets The total amount of underlying assets managed by the strategy
    function totalAssets() public view virtual override returns (uint256 assets) {
        return 0;
    }
}
