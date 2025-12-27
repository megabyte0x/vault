// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC4626, ERC20} from "@solady/tokens/ERC4626.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {Errors} from "./lib/Errors.sol";
import {SimpleTokenizedStrategy} from "./SimpleTokenizedStrategy.sol";
import {SimpleVaultWithTokenizedStrategyStorage} from "./SimpleVaultWithTokenizedStrategyStorage.sol";

/// @title SimpleVault
/// @notice An ERC-4626 compliant vault that integrates with DeFi protocols through a pluggable strategy
/// @dev Extends Solady's ERC4626 implementation with entry/exit fees and strategy delegation
/// @author megabyte0x.eth
contract SimpleVaultWithTokenizedStrategy is SimpleVaultWithTokenizedStrategyStorage, ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for address;

    /// @notice Initializes the vault with the specified underlying asset
    /// @param asset_ The address of the ERC20 token to be used as the underlying asset
    constructor(address asset_) SimpleVaultWithTokenizedStrategyStorage(asset_) {}

    /*
       _____      _                        _   _____                 _   _
      | ____|_  _| |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      |  _| \ \/ / __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      | |___ >  <| ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_____/_/\_\\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Sets the entry fee for deposits
    /// @param newEntryFee The new entry fee in basis points (e.g., 50 = 0.5%)
    //! TODO: Add access control modifiers
    function setEntryFee(uint256 newEntryFee) external {
        s_entryFee = newEntryFee;

        emit SimpleVault__EntryFeeUpdated(newEntryFee);
    }

    /// @notice Sets the exit fee for withdrawals
    /// @param newExitFee The new exit fee in basis points (e.g., 100 = 1%)
    //! TODO: Add access control modifiers
    function setExitFee(uint256 newExitFee) external {
        s_exitFee = newExitFee;

        emit SimpleVault__ExitFeeUpdated(newExitFee);
    }

    /// @notice Sets the address that will receive collected fees
    /// @param newFeeRecipient The new fee recipient address (cannot be zero address)
    //! TODO: Add access control modifiers
    function setFeeRecipient(address newFeeRecipient) external {
        if (newFeeRecipient == address(0)) revert Errors.ZeroAddress();

        s_feeRecipient = newFeeRecipient;

        emit SimpleVault__FeeRecipientUpdated(newFeeRecipient);
    }

    function addStrategy(address strategy, uint256 allocation) external {
        _validateStrategyAddition(strategy, allocation);

        s_strategiesToIndex[strategy] = s_totalStrategies + 1; // indexPlusOne
        s_strategies[s_totalStrategies] = Strategy({strategy: strategy, allocation: allocation});
        s_totalStrategies += 1;

        _reallocateFunds();

        emit SimpleVault__TokenizedStrategyAdded(strategy, allocation);
    }

    function removeStrategy(uint256 strategyIndex) external {}

    function replaceStrategy(uint256 strategyIndex, address newStrategy) external {}

    /*
       ____        _     _ _        _____                 _   _
      |  _ \ _   _| |__ | (_) ___  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
      | |_) | | | | '_ \| | |/ __| | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
      |  __/| |_| | |_) | | | (__  |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |_|    \__,_|_.__/|_|_|\___| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Returns the name of the vault token
    /// @inheritdoc ERC20
    /// @return The vault token name
    function name() public pure override returns (string memory) {
        return "Simple Vault w/ Tokenized Strategy";
    }

    /// @notice Returns the symbol of the vault token
    /// @inheritdoc ERC20
    /// @return The vault token symbol
    function symbol() public pure override returns (string memory) {
        return "SVTS";
    }

    /// @notice Returns the address of the underlying asset
    /// @inheritdoc ERC4626
    /// @return The address of the underlying ERC20 token
    function asset() public view override returns (address) {
        return i_asset;
    }

    /// @notice Previews the amount of shares that would be minted for a deposit
    /// @inheritdoc ERC4626
    /// @dev Deducts entry fees from assets before calculating shares
    /// @param assets The amount of assets to be deposited
    /// @return shares The amount of shares that would be minted (after fees)
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        uint256 fee = _feeOnTotal(assets, getEntryFee());
        return super.previewDeposit(assets.rawSub(fee));
    }

    /// @notice Previews the amount of assets needed to mint a specific amount of shares
    /// @inheritdoc ERC4626
    /// @dev Adds entry fees to the required assets
    /// @param shares The amount of shares to be minted
    /// @return assets The total amount of assets needed (including fees)
    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewMint(shares);
        return (assets.rawAdd(_feeOnRaw(assets, getEntryFee())));
    }

    /// @notice Previews the amount of shares needed to withdraw a specific amount of assets
    /// @inheritdoc ERC4626
    /// @dev Deducts exit fees from assets before calculating shares
    /// @param assets The amount of assets to be withdrawn
    /// @return shares The amount of shares that need to be burned
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        uint256 fee = _feeOnRaw(assets, getExitFee());
        return super.previewWithdraw(assets.rawAdd(fee));
    }

    /// @notice Previews the amount of assets that would be withdrawn for redeeming shares
    /// @inheritdoc ERC4626
    /// @dev Adds exit fees to the assets calculation
    /// @param shares The amount of shares to be redeemed
    /// @return assets The total amount of assets that would be withdrawn (including fees)
    function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
        assets = super.previewRedeem(shares);
        return (assets.rawSub(_feeOnTotal(assets, getExitFee())));
    }

    /// @notice Returns the total amount of assets under management
    /// @inheritdoc ERC4626
    /// @dev Delegates to the strategy contract to calculate total assets across all positions
    /// @return assets The total amount of underlying assets managed by the vault
    function totalAssets() public view override returns (uint256 assets) {
        uint256 i = 0;

        for (i; i < s_totalStrategies; i++) {
            assets = assets.rawAdd(_assetInStrategy(s_strategies[i].strategy));
        }

        /// @dev 3. Add the idle assets (if any)
        assets = assets.rawAdd(ERC20(i_asset).balanceOf(address(this)));
    }

    function maxWithdraw(address user) public view override returns (uint256 maxAssets) {
        uint256 balanceOfUser = convertToAssets(balanceOf(user));

        uint256 feeOnWithdraw = _feeOnTotal(balanceOfUser, getExitFee());

        maxAssets = balanceOfUser.rawSub(feeOnWithdraw);
    }

    /// @notice Returns the current entry fee in basis points
    /// @return The entry fee charged on deposits (in basis points)
    function getEntryFee() public view returns (uint256) {
        return s_entryFee;
    }

    function getStrategyIndex(address strategy) external view returns (uint256 index) {
        uint256 ip1 = s_strategiesToIndex[strategy];
        if (ip1 == 0) revert Errors.StrategyNotFound();
        index = ip1 - 1;
    }

    /// @notice Returns the current exit fee in basis points
    /// @return The exit fee charged on withdrawals (in basis points)
    function getExitFee() public view returns (uint256) {
        return s_exitFee;
    }

    function getFeeRecipient() external view returns (address) {
        return s_feeRecipient;
    }

    function getStrategyDetails(uint256 strategyIndex) external view returns (Strategy memory strategy) {
        strategy = s_strategies[strategyIndex];
    }

    /*
       ___       _                        _   _____                 _   _
      |_ _|_ __ | |_ ___ _ __ _ __   __ _| | |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
       | || '_ \| __/ _ \ '__| '_ \ / _` | | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
       | || | | | ||  __/ |  | | | | (_| | | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
      |___|_| |_|\__\___|_|  |_| |_|\__,_|_| |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    */

    /// @notice Internal function to handle deposits
    /// @inheritdoc ERC4626
    /// @dev Transfers entry fees to fee recipient and supplies remaining assets to strategy
    /// @param by The address initiating the deposit
    /// @param to The address receiving the shares
    /// @param assets The total amount of assets being deposited
    /// @param shares The amount of shares being minted
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal override {
        super._deposit(by, to, assets, shares);

        uint256 fee = _feeOnTotal(assets, getEntryFee());

        // Transfer entry fee to fee recipient (if fee exists and recipient is not this contract)
        if (fee > 0 && s_feeRecipient != address(this)) {
            i_asset.safeTransfer(s_feeRecipient, fee);
        }

        // Supply remaining assets to strategy for yield generation
        _allocateFundsInStrategies(assets.rawSub(fee));
    }

    /// @notice Internal function to handle withdrawals
    /// @inheritdoc ERC4626
    /// @dev Withdraws assets from strategy, transfers exit fees, and processes withdrawal
    /// @param by The address initiating the withdrawal
    /// @param to The address receiving the assets
    /// @param owner The address owning the shares being burned
    /// @param assets The total amount of assets being withdrawn
    /// @param shares The amount of shares being burned
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares) internal override {
        uint256 fee = _feeOnRaw(assets, getExitFee());

        // Transfer exit fee to fee recipient (if fee exists and recipient is not this contract)
        if (fee > 0 && s_feeRecipient != address(this)) {
            i_asset.safeTransfer(s_feeRecipient, fee);
        }

        uint256 assetsToTransfer = assets.rawSub(fee);

        // Withdraw assets from strategy
        // s_strategy.withdraw(assetsToTransfer, address(this), address(this));

        // Complete the withdrawal process
        super._withdraw(by, to, owner, assetsToTransfer, shares);
    }

    function _allocateFundsInStrategies(uint256 assetToDeposit) internal {
        uint256 i = 0;

        mapping(uint256 => Strategy) storage strategies = s_strategies;

        for (i; i < s_totalStrategies; i++) {
            SimpleTokenizedStrategy(strategies[i].strategy)
                .deposit(assetToDeposit.mulDiv(strategies[i].allocation, BASIS_POINT_SCALE), address(this));
        }
    }

    function _reallocateFunds() internal {
        uint256 currentTotalAssets;

        uint256 i = 0;

        uint256 currentIdleAssetBalance = i_asset.balanceOf(address(this));
        uint256[] memory currentAssetsBalances = new uint256[](s_totalStrategies);

        uint256 totalAssetBalanceAcrossStrategies;

        for (i; i < s_totalStrategies; i++) {
            currentAssetsBalances[i] = _assetInStrategy(s_strategies[i].strategy);
            totalAssetBalanceAcrossStrategies = totalAssetBalanceAcrossStrategies.rawAdd(currentAssetsBalances[i]);
        }

        currentTotalAssets = totalAssetBalanceAcrossStrategies.rawAdd(currentIdleAssetBalance);

        uint256 targetIdleAllocation = BASIS_POINT_SCALE.rawSub(_currentTotalAllocation());

        uint256 targetIdleAssetBalance = currentTotalAssets.mulDiv(targetIdleAllocation, BASIS_POINT_SCALE);

        i = 0;
        /**
         * @dev This loop withdraw assets if they are in excess.
         * This condition occurs when Price per share increases.
         */
        for (i; i < s_totalStrategies; i++) {
            uint256 targetAssetBalance = currentTotalAssets.mulDiv(s_strategies[i].allocation, BASIS_POINT_SCALE);
            if (currentAssetsBalances[i] > targetAssetBalance) {
                uint256 excess = currentAssetsBalances[i].rawSub(targetAssetBalance);
                uint256 maxWithdrawable = SimpleTokenizedStrategy(s_strategies[i].strategy).maxWithdraw(address(this));

                uint256 amountToWithdraw = excess.min(maxWithdrawable);

                if (amountToWithdraw == 0) continue;

                SimpleTokenizedStrategy(s_strategies[i].strategy)
                    .withdraw(amountToWithdraw, address(this), address(this));

                currentIdleAssetBalance = currentIdleAssetBalance.rawAdd(amountToWithdraw);
                currentAssetsBalances[i] = currentAssetsBalances[i].rawSub(amountToWithdraw);
            }
        }
        uint256 deployable;

        if (currentIdleAssetBalance >= targetIdleAssetBalance) {
            deployable = currentIdleAssetBalance.rawSub(targetIdleAssetBalance);

            i = 0;
            for (i; i < s_totalStrategies; i++) {
                uint256 targetAssetBalance = currentTotalAssets.mulDiv(s_strategies[i].allocation, BASIS_POINT_SCALE);
                if (currentAssetsBalances[i] < targetAssetBalance) {
                    uint256 need = targetAssetBalance.rawSub(currentAssetsBalances[i]);

                    uint256 amountToDeposit = need.min(deployable);

                    if (amountToDeposit == 0) break;

                    uint256 sharesReceived =
                        SimpleTokenizedStrategy(s_strategies[i].strategy).deposit(amountToDeposit, address(this));

                    deployable = deployable.rawSub(amountToDeposit);
                    currentAssetsBalances[i] = currentAssetsBalances[i].rawAdd(
                        SimpleTokenizedStrategy(s_strategies[i].strategy).convertToAssets(sharesReceived)
                    );
                }
            }
        }
    }

    /// @notice Returns the number of decimals used by the underlying asset
    /// @inheritdoc ERC4626
    /// @dev Used internally for precise share calculations
    /// @return The number of decimals of the underlying asset
    function _underlyingDecimals() internal view override returns (uint8) {
        return ERC20(i_asset).decimals();
    }

    function _currentTotalAllocation() internal view returns (uint256 currentTotalAllocation) {
        uint256 i = 0;

        for (i; i < s_totalStrategies; i++) {
            currentTotalAllocation = currentTotalAllocation.rawAdd(s_strategies[i].allocation);
        }
    }

    function _validateTotalAllocation(uint256 allocation) internal view {
        if (allocation == 0) revert Errors.ZeroAmount();

        if (_currentTotalAllocation() > BASIS_POINT_SCALE - allocation) {
            revert Errors.TotalAllocationExceeded();
        }
    }

    function _validateStrategyAddition(address strategy, uint256 allocation) internal view {
        if (strategy == address(0)) revert Errors.ZeroAddress();
        if (s_totalStrategies >= MAX_STRATEGIES) revert Errors.MaxStrategiesReached();
        if (SimpleTokenizedStrategy(strategy).asset() != i_asset) revert Errors.WrongBaseAsset();

        if (s_strategiesToIndex[strategy] != 0) revert Errors.StrategyAlreadyAdded();

        _validateTotalAllocation(allocation);
    }

    function _assetInStrategy(address strategy) internal view returns (uint256 assets) {
        /// @dev 1. Get the number of strategy shares.
        uint256 strategySharesBalance = SimpleTokenizedStrategy(strategy).balanceOf(address(this));

        /// @dev 2. Convert the strategy shares into base assets and add them all.
        assets = SimpleTokenizedStrategy(strategy).convertToAssets(strategySharesBalance);
    }

    /// @dev Calculates the fees that should be added to an amount `assets` that does not already include fees.
    /// Used in {ERC4626-mint} and {ERC4626-withdraw} operations.
    function _feeOnRaw(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, BASIS_POINT_SCALE);
    }

    /// @dev Calculates the fee part of an amount `assets` that already includes fees.
    /// Used in {ERC4626-deposit} and {ERC4626-redeem} operations.
    function _feeOnTotal(uint256 assets, uint256 feeBasisPoints) internal pure returns (uint256) {
        return assets.mulDivUp(feeBasisPoints, feeBasisPoints + BASIS_POINT_SCALE);
    }
}

//  /**
//              * In both the conditions if the difference is really minimal (dust equivalent) the loop should continue.
//              * TODO: Finalise the dust amount which can be ignored.
//              */

//             /**
//              * @dev When the strategy is at loss and have less funds than deposited.
//              * In this case we will need to `deposit` more funds to *this* strategy from another strategy to maintain allocation ratio.
//              */
//             if (targetAllocation > currentAllocation) {}
//             /**
//              * @dev When the strategy is in profit and have more assets than deposited.
//              * In this case we will need to *withdraw` funds from *this* strategy.
//              * Withdraw funds can be used to be allocated in strategy where allocation is lacking or can sit idle.
//              */
//             else if (targetAllocation < currentAllocation) {}
//             /**
//              * @dev No change in assets since deposited.
//              * This case shouldn't occur as the shares minted while depositing in a strategy vault uses `mulDivDown`.
//              */
//             else {
//                 continue;
//             }
