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

/**
 * @title Simple Strategy
 * @author megabyte
 * @notice This is a simple vault strategy which spilts the 80% of the deposited amount equally between Morpho and Aave.
 */

contract SimpleStrategy is ISimpleStrategy {
    using Address for address;
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    IAave public immutable i_aave;
    IMorpho public immutable i_morpho;
    address public immutable i_vault;

    uint16 internal constant REFERRAL_CODE = 0;
    uint256 internal constant SPILT_PERCENTAGE = 50_00;
    uint256 internal constant PERCENTAGE_TO_DEPOSIT = 80_00;
    uint256 internal constant BASIS_POINT_SCALE = 100_00;

    constructor(address vault_, address aave_, address morpho_) {
        i_aave = IAave(aave_);
        i_morpho = IMorpho(morpho_);
        i_vault = vault_;
    }

    function asset() public view returns (address assetAddress) {
        bytes memory data = i_vault.functionStaticCall(abi.encodeWithSignature("asset()"));

        assetAddress = abi.decode(data, (address));
    }

    function totalAssets() public view returns (uint256 totalBalance) {
        uint256 balanceInVault = ERC20(asset()).balanceOf(i_vault);

        uint256 totalBalanceInDifferentMarkets = getTotalBalanceInMarkets();

        totalBalance = balanceInVault + totalBalanceInDifferentMarkets;
    }

    function supply(uint256 amount) external {
        uint256 amountToDeposit = amount.mulDivUp(PERCENTAGE_TO_DEPOSIT, BASIS_POINT_SCALE);

        address token = asset();

        token.safeTransferFrom(i_vault, address(this), amountToDeposit);

        uint256 amountToDepositInAave = amountToDeposit.mulDiv(SPILT_PERCENTAGE, BASIS_POINT_SCALE);
        uint256 amountToDepositInMorpho = amountToDeposit.rawSub(amountToDepositInAave);

        token.safeApprove(address(i_aave), amountToDepositInAave);
        i_aave.supply(asset(), amountToDepositInAave, address(this), REFERRAL_CODE);

        token.safeApprove(address(i_morpho), amountToDepositInMorpho);
        i_morpho.deposit(amountToDepositInMorpho, address(this));
    }

    function withdraw(uint256 amount) external {
        console2.log("amount to withdraw: ", amount);

        uint256 currentBalanceInVault = ERC20(asset()).balanceOf(i_vault);
        console2.log("Current balance in vault: ", currentBalanceInVault);

        if (amount > currentBalanceInVault) _reallocateAssets(amount, currentBalanceInVault);
    }

    function withdrawFunds() external {
        _withdrawFunds();
    }

    function getTotalBalanceInMarkets() public view returns (uint256 totalBalance) {
        return _getBalanceInAave() + _getBalanceInMorpho();
    }

    function _getBalanceInAave() internal view returns (uint256 balance) {
        address aToken = IAave(i_aave).getReserveAToken(asset());
        balance = ERC20(aToken).balanceOf(address(this));
    }

    function _getBalanceInMorpho() internal view returns (uint256 balance) {
        uint256 shares = i_morpho.balanceOf(address(this));
        balance = i_morpho.convertToAssets(shares);
    }

    function _reallocateAssets(uint256 amountToWithdraw, uint256 currentBalanceInVault) internal {
        uint256 totalBalance = totalAssets();

        uint256 percentageToRemainUnallocated = BASIS_POINT_SCALE.rawSub(PERCENTAGE_TO_DEPOSIT);

        console2.log("total balance: ", totalBalance);

        uint256 totalBalanceAfter = totalBalance.rawSub(amountToWithdraw);
        console2.log("total balance after: ", totalBalanceAfter);

        if (totalBalanceAfter < _singleUnitAsset()) {
            _withdrawFunds();
        } else {
            uint256 targetToUnallocate = ((totalBalanceAfter.mulDivUp(percentageToRemainUnallocated, BASIS_POINT_SCALE))
                .rawAdd(amountToWithdraw))
            .rawSub(currentBalanceInVault);

            console2.log("targetToUnallocate, ", targetToUnallocate);

            _reallocate(targetToUnallocate);
        }
    }

    function _reallocate(uint256 totalBalanceToWithdraw) internal {
        uint256 balanceToWithdrawFromAave = totalBalanceToWithdraw.mulDiv(SPILT_PERCENTAGE, BASIS_POINT_SCALE);

        i_aave.withdraw(asset(), balanceToWithdrawFromAave, i_vault);

        i_morpho.withdraw(totalBalanceToWithdraw - balanceToWithdrawFromAave, i_vault, address(this));
    }

    function _withdrawFunds() internal {
        i_aave.withdraw(asset(), _getBalanceInAave(), i_vault);

        i_morpho.withdraw(_getBalanceInMorpho(), i_vault, address(this));
    }

    function _singleUnitAsset() internal view returns (uint256) {
        return 1 * 10 ** ERC20(asset()).decimals();
    }
}
