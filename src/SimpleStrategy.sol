// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {Address} from "@openzeppelin/utils/Address.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IVaultV2 as IMorpho} from "@morpho/interfaces/IVaultV2.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

import {ISimpleStrategy} from "./interfaces/ISimpleStrategy.sol";
import {IPool as IAave} from "./interfaces/IAavePool.sol";

/// @title SimpleStrategy
/// @notice A yield strategy that splits 80% of deposited assets equally between Aave and Morpho protocols
/// @dev Implements ISimpleStrategy interface and manages asset allocation across DeFi protocols
/// @author megabyte0x.eth

contract SimpleStrategy is ISimpleStrategy {
    using Address for address;
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @notice The Aave lending pool contract
    IAave public immutable i_aave;

    /// @notice The Morpho vault contract
    IMorpho public immutable i_morpho;

    /// @notice The vault contract that owns this strategy
    address public immutable i_vault;

    /// @notice Referral code for Aave deposits (0 = no referral)
    uint16 internal constant REFERRAL_CODE = 0;

    /// @notice Percentage split between Aave and Morpho (50% each)
    uint256 internal constant SPILT_PERCENTAGE = 50_00;

    /// @notice Percentage of vault assets to deploy in strategy (80%)
    uint256 internal constant PERCENTAGE_TO_DEPOSIT = 80_00;

    /// @notice Scale factor for percentage calculations (100%)
    uint256 internal constant BASIS_POINT_SCALE = 100_00;

    /// @notice Initializes the strategy with required protocol addresses
    /// @param vault_ The address of the vault that will use this strategy
    /// @param aave_ The address of the Aave lending pool
    /// @param morpho_ The address of the Morpho vault
    constructor(address vault_, address aave_, address morpho_) {
        i_aave = IAave(aave_);
        i_morpho = IMorpho(morpho_);
        i_vault = vault_;
    }

    /// @notice Returns the underlying asset address by querying the vault
    /// @dev Uses OpenZeppelin's Address library for safe static calls
    /// @return assetAddress The address of the underlying ERC20 asset
    function asset() public view returns (address assetAddress) {
        bytes memory data = i_vault.functionStaticCall(abi.encodeWithSignature("asset()"));

        assetAddress = abi.decode(data, (address));
    }

    /// @notice Returns the total assets under management across all positions
    /// @dev Sums vault balance and deployed assets in external protocols
    /// @return totalBalance The total amount of assets managed by this strategy
    function totalAssets() public view returns (uint256 totalBalance) {
        uint256 balanceInVault = ERC20(asset()).balanceOf(i_vault);

        uint256 totalBalanceInDifferentMarkets = getTotalBalanceInMarkets();

        totalBalance = balanceInVault + totalBalanceInDifferentMarkets;
    }

    /// @notice Supplies assets to external protocols according to strategy allocation
    /// @dev Deploys 80% of amount equally between Aave (40%) and Morpho (40%), leaves 20% in vault
    /// @param amount The total amount of assets to be deployed
    function supply(uint256 amount) external {
        // Calculate 80% of the amount to deploy
        uint256 amountToDeposit = amount.mulDivUp(PERCENTAGE_TO_DEPOSIT, BASIS_POINT_SCALE);

        address token = asset();

        // Transfer assets from vault to strategy
        token.safeTransferFrom(i_vault, address(this), amountToDeposit);

        // Split equally between Aave and Morpho (50% each of deployed amount)
        uint256 amountToDepositInAave = amountToDeposit.mulDiv(SPILT_PERCENTAGE, BASIS_POINT_SCALE);
        uint256 amountToDepositInMorpho = amountToDeposit.rawSub(amountToDepositInAave);

        // Supply to Aave
        token.safeApprove(address(i_aave), amountToDepositInAave);
        i_aave.supply(asset(), amountToDepositInAave, address(this), REFERRAL_CODE);

        // Supply to Morpho
        token.safeApprove(address(i_morpho), amountToDepositInMorpho);
        i_morpho.deposit(amountToDepositInMorpho, address(this));
    }

    /// @notice Withdraws the requested amount by reallocating assets if necessary
    /// @dev If vault doesn't have enough balance, triggers reallocation from external protocols
    /// @param amount The amount of assets to make available for withdrawal
    function withdraw(uint256 amount) external {
        //! TODO: Remove debug console logs before production
        console2.log("amount to withdraw: ", amount);

        uint256 currentBalanceInVault = ERC20(asset()).balanceOf(i_vault);
        console2.log("Current balance in vault: ", currentBalanceInVault);

        // Reallocate assets if vault doesn't have sufficient balance
        if (amount > currentBalanceInVault) _reallocateAssets(amount, currentBalanceInVault);
    }

    /// @notice Withdraws all funds from external protocols back to the vault
    /// @dev Called when strategy is being replaced or vault needs to liquidate all positions
    function withdrawFunds() external {
        _withdrawFunds();
    }

    /// @notice Returns the total balance deployed across external protocols
    /// @dev Sums balances in Aave and Morpho
    /// @return totalBalance The total amount deployed in external protocols
    function getTotalBalanceInMarkets() public view returns (uint256 totalBalance) {
        return _getBalanceInAave() + _getBalanceInMorpho();
    }

    /// @notice Gets the balance of assets deposited in Aave
    /// @dev Queries the aToken balance which represents deposits in Aave
    /// @return balance The amount of assets deposited in Aave
    function _getBalanceInAave() internal view returns (uint256 balance) {
        address aToken = IAave(i_aave).getReserveAToken(asset());
        balance = ERC20(aToken).balanceOf(address(this));
    }

    /// @notice Gets the balance of assets deposited in Morpho
    /// @dev Converts Morpho vault shares to underlying asset amount
    /// @return balance The amount of assets deposited in Morpho
    function _getBalanceInMorpho() internal view returns (uint256 balance) {
        uint256 shares = i_morpho.balanceOf(address(this));
        balance = i_morpho.convertToAssets(shares);
    }

    /// @notice Reallocates assets from external protocols to meet withdrawal requirements
    /// @dev Maintains 20% unallocated ratio while providing sufficient vault balance
    /// @param amountToWithdraw The amount that needs to be withdrawn
    /// @param currentBalanceInVault The current balance available in the vault
    function _reallocateAssets(uint256 amountToWithdraw, uint256 currentBalanceInVault) internal {
        uint256 totalBalance = totalAssets();

        uint256 percentageToRemainUnallocated = BASIS_POINT_SCALE.rawSub(PERCENTAGE_TO_DEPOSIT);

        //! TODO: Remove debug console logs before production
        console2.log("total balance: ", totalBalance);

        uint256 totalBalanceAfter = totalBalance.rawSub(amountToWithdraw);
        console2.log("total balance after: ", totalBalanceAfter);

        // If remaining balance is too small, withdraw everything
        if (totalBalanceAfter < _singleUnitAsset()) {
            _withdrawFunds();
        } else {
            // Calculate how much to withdraw to maintain proper allocation ratio
            uint256 targetToUnallocate = ((totalBalanceAfter.mulDivUp(percentageToRemainUnallocated, BASIS_POINT_SCALE))
                .rawAdd(amountToWithdraw))
            .rawSub(currentBalanceInVault);

            console2.log("targetToUnallocate, ", targetToUnallocate);

            _reallocate(targetToUnallocate);
        }
    }

    /// @notice Withdraws specified amount from external protocols proportionally
    /// @dev Withdraws equally from Aave and Morpho to maintain balance
    /// @param totalBalanceToWithdraw The total amount to withdraw from external protocols
    function _reallocate(uint256 totalBalanceToWithdraw) internal {
        uint256 balanceToWithdrawFromAave = totalBalanceToWithdraw.mulDiv(SPILT_PERCENTAGE, BASIS_POINT_SCALE);

        // Withdraw proportional amount from Aave directly to vault
        i_aave.withdraw(asset(), balanceToWithdrawFromAave, i_vault);

        // Withdraw remaining amount from Morpho directly to vault
        i_morpho.withdraw(totalBalanceToWithdraw - balanceToWithdrawFromAave, i_vault, address(this));
    }

    /// @notice Internal function to withdraw all funds from external protocols
    /// @dev Withdraws entire balance from both Aave and Morpho back to vault
    function _withdrawFunds() internal {
        // Withdraw all from Aave directly to vault
        i_aave.withdraw(asset(), _getBalanceInAave(), i_vault);

        // Withdraw all from Morpho directly to vault
        i_morpho.withdraw(_getBalanceInMorpho(), i_vault, address(this));
    }

    /// @notice Returns one unit of the underlying asset (1.0 in asset's decimal precision)
    /// @dev Used as a threshold for determining when to withdraw all funds
    /// @return One unit of the asset (e.g., 1e6 for USDC)
    function _singleUnitAsset() internal view returns (uint256) {
        return 1 * 10 ** ERC20(asset()).decimals();
    }
}
