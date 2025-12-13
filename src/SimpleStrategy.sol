// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Address} from "@openzeppelin/utils/Address.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IVaultV2 as IMorpho} from "@morpho/interfaces/IVaultV2.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

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

    function totalAssetsInVault() external view returns (uint256 totalAssets) {
        uint256 assetInVault = IERC20(asset()).balanceOf(i_vault);

        uint256 totalBalanceInDifferentMarkets = _getTotalBalanceInMarkets();

        totalAssets = assetInVault + totalBalanceInDifferentMarkets;
    }

    function supply(uint256 amount) external {
        uint256 amountToDeposit = amount.mulDivUp(PERCENTAGE_TO_DEPOSIT, BASIS_POINT_SCALE);

        address token = asset();

        token.safeTransferFrom(i_vault, address(this), amountToDeposit);

        uint256 amountToDepositInAave = amountToDeposit.mulDivUp(1, 2);

        token.safeApprove(address(i_aave), amountToDepositInAave);
        i_aave.supply(asset(), amountToDepositInAave, i_vault, REFERRAL_CODE);

        uint256 amountToDepositInMorpho = amountToDeposit.rawSub(amountToDepositInAave);

        token.safeApprove(address(i_morpho), amountToDepositInMorpho);
        i_morpho.deposit(amountToDepositInMorpho, i_vault);
    }

    function withdraw(uint256 amount) external {
        i_aave.withdraw(asset(), amount, i_vault);
    }

    function _getTotalBalanceInMarkets() internal view returns (uint256 totalBalance) {
        return _getBalanceInAave() + _getBalanceInMorpho();
    }

    function _getBalanceInAave() internal view returns (uint256 balance) {
        address aToken = IAave(i_aave).getReserveAToken(asset());
        balance = IERC20(aToken).balanceOf(i_vault);
    }

    function _getBalanceInMorpho() internal view returns (uint256 balance) {
        uint256 shares = i_morpho.balanceOf(i_vault);
        balance = i_morpho.convertToAssets(shares);
    }
}
