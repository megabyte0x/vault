// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// src/contracts/protocol/libraries/types/DataTypes.sol

library DataTypes {
    /**
     * This exists specifically to maintain the `getReserveData()` interface, since the new, internal
     * `ReserveData` struct includes the reserve's `virtualUnderlyingBalance`.
     */
    struct ReserveDataLegacy {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        // DEPRECATED on v3.2.0
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        // DEPRECATED on v3.2.0
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        // DEPRECATED on v3.4.0, should use the `RESERVE_INTEREST_RATE_STRATEGY` variable from the Pool contract
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        // DEPRECATED on v3.4.0
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        /// @notice reused `__deprecatedStableBorrowRate` storage from pre 3.2
        // the current accumulate deficit in underlying tokens
        uint128 deficit;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed
        uint40 liquidationGracePeriodUntil;
        //aToken address
        address aTokenAddress;
        // DEPRECATED on v3.2.0
        address __deprecatedStableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        // DEPRECATED on v3.4.0, should use the `RESERVE_INTEREST_RATE_STRATEGY` variable from the Pool contract
        address __deprecatedInterestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        // In aave 3.3.0 this storage slot contained the `unbacked`
        uint128 virtualUnderlyingBalance;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
        //the amount of underlying accounted for by the protocol
        // DEPRECATED on v3.4.0. Moved into the same slot as accruedToTreasury for optimized storage access.
        uint128 __deprecatedVirtualUnderlyingBalance;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: DEPRECATED: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62: siloed borrowing enabled
        //bit 63: flashloaning enabled
        //bit 64-79: reserve factor
        //bit 80-115: borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167: liquidation protocol fee
        //bit 168-175: DEPRECATED: eMode category
        //bit 176-211: DEPRECATED: unbacked mint cap
        //bit 212-251: debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252: DEPRECATED: virtual accounting is enabled for the reserve
        //bit 253-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    // DEPRECATED: kept for backwards compatibility, might be removed in a future version
    struct EModeCategoryLegacy {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // DEPRECATED
        address priceSource;
        string label;
    }

    struct CollateralConfig {
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
    }

    struct EModeCategoryBaseConfiguration {
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        string label;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        uint128 collateralBitmap;
        string label;
        uint128 borrowableBitmap;
    }

    enum InterestRateMode {
        NONE,
        __DEPRECATED,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        address liquidator;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address borrower;
        bool receiveAToken;
        address priceOracle;
        uint8 borrowerEModeCategory;
        address priceOracleSentinel;
        address interestRateStrategyAddress;
    }

    struct ExecuteSupplyParams {
        address user;
        address asset;
        address interestRateStrategyAddress;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        address interestRateStrategyAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        address user;
        address interestRateStrategyAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteWithdrawParams {
        address user;
        address asset;
        address interestRateStrategyAddress;
        uint256 amount;
        address to;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteEliminateDeficitParams {
        address user;
        address asset;
        address interestRateStrategyAddress;
        uint256 amount;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 scaledAmount;
        uint256 scaledBalanceFromBefore;
        uint256 scaledBalanceToBefore;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address user;
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address interestRateStrategyAddress;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremium;
        address addressesProvider;
        address pool;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address user;
        address receiverAddress;
        address asset;
        address interestRateStrategyAddress;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremium;
    }

    struct FlashLoanRepaymentParams {
        address user;
        uint256 amount;
        uint256 totalPremium;
        address asset;
        address interestRateStrategyAddress;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amountScaled;
        InterestRateMode interestRateMode;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
        address borrower;
        address liquidator;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalDebt;
        uint256 reserveFactor;
        address reserve;
        // @notice DEPRECATED in 3.4, but kept for backwards compatibility
        bool usingVirtualBalance;
        uint256 virtualUnderlyingBalance;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address variableDebtAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// src/contracts/interfaces/IPoolAddressesProvider.sol

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     */
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple Aave markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     */
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// src/contracts/interfaces/IPool.sol

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 2 for Variable, 1 is deprecated (changed on v3.2.0)
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useATokens
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     */
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan,
     *        1 for Stable (Deprecated on v3.2.0), 2 for Variable
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate @note deprecated on v3.2.0
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the deficit of a reserve is covered.
     * @param reserve The address of the underlying asset of the reserve
     * @param caller The caller that triggered the DeficitCovered event
     * @param amountCovered The amount of deficit covered
     */
    event DeficitCovered(address indexed reserve, address caller, uint256 amountCovered);

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Emitted when deficit is realized on a liquidation.
     * @param user The user address where the bad debt will be burned
     * @param debtAsset The address of the underlying borrowed asset to be burned
     * @param amountCreated The amount of deficit created
     */
    event DeficitCreated(address indexed user, address indexed debtAsset, uint256 amountCreated);

    /**
     * @dev Emitted when a position manager is approved by the user.
     * @param user The user address
     * @param positionManager The address of the position manager
     */
    event PositionManagerApproved(address indexed user, address indexed positionManager);

    /**
     * @dev Emitted when a position manager is revoked by the user.
     * @param user The user address
     * @param positionManager The address of the position manager
     */
    event PositionManagerRevoked(address indexed user, address indexed positionManager);

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the VariableDebtToken
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 variable debt tokens
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode 2 for Variable, 1 is deprecated on v3.2.0
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     */
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode 2 for Variable, 1 is deprecated on v3.2.0
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     */
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode 2 for Variable, 1 is deprecated on v3.2.0
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode DEPRECATED in v3.2.0
     * @return The final amount repaid
     */
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param borrower The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address borrower,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Deprecated on v3.2.0
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using 2 on `modes`
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     */
    function initReserve(address asset, address aTokenAddress, address variableDebtAddress) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @dev Does not reset eMode flags, which must be considered when reusing the same reserve id for a different reserve.
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice Accumulates interest to all indexes of the reserve
     * @dev Only callable by the PoolConfigurator contract
     * @dev To be used when required by the configurator, for example when updating interest rates strategy data
     * @param asset The address of the underlying asset of the reserve
     */
    function syncIndexesState(address asset) external;

    /**
     * @notice Updates interest rates on the reserve data
     * @dev Only callable by the PoolConfigurator contract
     * @dev To be used when required by the configurator, for example when updating interest rates strategy data
     * @param asset The address of the underlying asset of the reserve
     */
    function syncRatesState(address asset) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
     * "dynamic" variable index based on time, current stored index and virtual rate at the current
     * moment (approx. a borrower would get if opening a position). This means that is always used in
     * combination with variable debt supply/balances.
     * If using this function externally, consider that is possible to have an increasing normalized
     * variable debt that is not equivalent to how the variable debt index would be updated in storage
     * (e.g. only updates with non-zero variable debt supply)
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveDataLegacy memory);

    /**
     * @notice Returns the virtual underlying balance of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve virtual underlying balance
     */
    function getVirtualUnderlyingBalance(address asset) external view returns (uint128);

    /**
     * @notice Validates and finalizes an aToken transfer
     * @dev Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param scaledAmount The scaled amount being transferred/withdrawn
     * @param scaledBalanceFromBefore The aToken scaled balance of the `from` user before the transfer
     * @param scaledBalanceToBefore The aToken scaled balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 scaledAmount,
        uint256 scaledBalanceFromBefore,
        uint256 scaledBalanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the number of initialized reserves
     * @dev It includes dropped reserves
     * @return The count
     */
    function getReservesCount() external view returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns the ReserveInterestRateStrategy connected to all the reserves
     * @return The address of the ReserveInterestRateStrategy contract
     */
    function RESERVE_INTEREST_RATE_STRATEGY() external view returns (address);

    /**
     * @notice Updates flash loan premium. All this premium is collected by the protocol treasury.
     * @dev The premium is calculated on the total borrowed amount
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremium The flash loan premium, expressed in bps
     */
    function updateFlashloanPremium(uint128 flashLoanPremium) external;

    /**
     * @notice Configures a new or alters an existing collateral configuration of an eMode.
     * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     * The category 0 is reserved as it's the default for volatile assets
     * @param id The id of the category
     * @param config The configuration of the category
     */
    function configureEModeCategory(uint8 id, DataTypes.EModeCategoryBaseConfiguration memory config) external;

    /**
     * @notice Replaces the current eMode collateralBitmap.
     * @param id The id of the category
     * @param collateralBitmap The collateralBitmap of the category
     */
    function configureEModeCategoryCollateralBitmap(uint8 id, uint128 collateralBitmap) external;

    /**
     * @notice Replaces the current eMode borrowableBitmap.
     * @param id The id of the category
     * @param borrowableBitmap The borrowableBitmap of the category
     */
    function configureEModeCategoryBorrowableBitmap(uint8 id, uint128 borrowableBitmap) external;

    /**
     * @notice Returns the data of an eMode category
     * @dev DEPRECATED use independent getters instead
     * @param id The id of the category
     * @return The configuration data of the category
     */
    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategoryLegacy memory);

    /**
     * @notice Returns the label of an eMode category
     * @param id The id of the category
     * @return The label of the category
     */
    function getEModeCategoryLabel(uint8 id) external view returns (string memory);

    /**
     * @notice Returns the collateral config of an eMode category
     * @param id The id of the category
     * @return The ltv,lt,lb of the category
     */
    function getEModeCategoryCollateralConfig(uint8 id) external view returns (DataTypes.CollateralConfig memory);

    /**
     * @notice Returns the collateralBitmap of an eMode category
     * @param id The id of the category
     * @return The collateralBitmap of the category
     */
    function getEModeCategoryCollateralBitmap(uint8 id) external view returns (uint128);

    /**
     * @notice Returns the borrowableBitmap of an eMode category
     * @param id The id of the category
     * @return The borrowableBitmap of the category
     */
    function getEModeCategoryBorrowableBitmap(uint8 id) external view returns (uint128);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
     * @param user The address of the user
     * @return The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
     * @dev It requires the given asset has zero debt ceiling
     * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Sets the liquidation grace period of the given asset
     * @dev To enable a liquidation grace period, a timestamp in the future should be set,
     *      To disable a liquidation grace period, any timestamp in the past works, like 0
     * @param asset The address of the underlying asset to set the liquidationGracePeriod
     * @param until Timestamp when the liquidation grace period will end
     *
     */
    function setLiquidationGracePeriod(address asset, uint40 until) external;

    /**
     * @notice Returns the liquidation grace period of the given asset
     * @param asset The address of the underlying asset
     * @return Timestamp when the liquidation grace period will end
     *
     */
    function getLiquidationGracePeriod(address asset) external view returns (uint40);

    /**
     * @notice Returns the total fee on flash loans.
     * @dev From v3.4 all flashloan fees will be send to the treasury.
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @dev From v3.4 all flashloan fees will be send to the treasury and this value
     *      is always 100_00.
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice It covers the deficit of a specified reserve by burning the equivalent aToken `amount` for assets
     * @dev The deficit of a reserve can occur due to situations where borrowed assets are not repaid, leading to bad debt.
     * @param asset The address of the underlying asset to cover the deficit.
     * @param amount The amount to be covered, in aToken
     * @return The amount of tokens burned
     */
    function eliminateReserveDeficit(address asset, uint256 amount) external returns (uint256);

    /**
     * @notice Approves or disapproves a position manager. This position manager will be able
     * to call the `setUserUseReserveAsCollateralOnBehalfOf` and the
     * `setUserEModeOnBehalfOf` function on behalf of the user.
     * @param positionManager The address of the position manager
     * @param approve True if the position manager should be approved, false otherwise
     */
    function approvePositionManager(address positionManager, bool approve) external;

    /**
     * @notice Renounces a position manager role for a given user.
     * @param user The address of the user
     */
    function renouncePositionManagerRole(address user) external;

    /**
     * @notice Sets the use as collateral flag for the user on the specific reserve on behalf of the user.
     * @param asset The address of the underlying asset of the reserve
     * @param useAsCollateral True if the user wants to use the reserve as collateral, false otherwise
     * @param onBehalfOf The address of the user
     */
    function setUserUseReserveAsCollateralOnBehalfOf(address asset, bool useAsCollateral, address onBehalfOf) external;

    /**
     * @notice Sets the eMode category for the user on the specific reserve on behalf of the user.
     * @param categoryId The id of the category
     * @param onBehalfOf The address of the user
     */
    function setUserEModeOnBehalfOf(uint8 categoryId, address onBehalfOf) external;

    /*
     * @notice Returns true if the `positionManager` address is approved to use the position manager role on behalf of the user.
     * @param user The address of the user
     * @param positionManager The address of the position manager
     * @return True if the user is approved to use the position manager, false otherwise
     */
    function isApprovedPositionManager(address user, address positionManager) external view returns (bool);

    /**
     * @notice Returns the current deficit of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @return The current deficit of the reserve
     */
    function getReserveDeficit(address asset) external view returns (uint256);

    /**
     * @notice Returns the aToken address of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @return The address of the aToken
     */
    function getReserveAToken(address asset) external view returns (address);

    /**
     * @notice Returns the variableDebtToken address of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @return The address of the variableDebtToken
     */
    function getReserveVariableDebtToken(address asset) external view returns (address);

    /**
     * @notice Gets the address of the external FlashLoanLogic
     */
    function getFlashLoanLogic() external view returns (address);

    /**
     * @notice Gets the address of the external BorrowLogic
     */
    function getBorrowLogic() external view returns (address);

    /**
     * @notice Gets the address of the external EModeLogic
     */
    function getEModeLogic() external view returns (address);

    /**
     * @notice Gets the address of the external LiquidationLogic
     */
    function getLiquidationLogic() external view returns (address);

    /**
     * @notice Gets the address of the external PoolLogic
     */
    function getPoolLogic() external view returns (address);

    /**
     * @notice Gets the address of the external SupplyLogic
     */
    function getSupplyLogic() external view returns (address);
}

