// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "@devops/src/DevOpsTools.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address usdc;
        address morpho_vault;
        address aave_pool;
        address usdc_holder;
        uint256 entryFee;
        uint256 exitFee;
    }

    address internal constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant ETH_MORPHO_VAULT = 0xbeeff2C5bF38f90e3482a8b19F12E5a6D2FCa757;
    address internal constant ETH_AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address internal constant ETH_USDC_HOLDER = 0xE20d20b0cC4e44Cd23D5B0488D5250A9ac426875;
    address public constant FEE_RECIPIENT = 0xdDCc06f98A7C71Ab602b8247d540dA5BD8f5D2A2;

    uint256 internal constant ENTRY_FEE = 5; // 0.05% in BPS
    uint256 internal constant EXIT_FEE = 10; // 0.1% in BPS

    function getNetworkConfig() public view returns (NetworkConfig memory config) {
        if (block.chainid == 1) {
            config = getMainnetConfig();
        }
    }

    function getVault() public view returns (address vault) {
        vault = _getAddress("SimpleVault");
    }

    function getStrategy() public view returns (address vault) {
        vault = _getAddress("SimpleStrategy");
    }

    function getMainnetConfig() internal pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            usdc: ETH_USDC,
            morpho_vault: ETH_MORPHO_VAULT,
            aave_pool: ETH_AAVE_POOL,
            entryFee: ENTRY_FEE,
            exitFee: EXIT_FEE,
            usdc_holder: ETH_USDC_HOLDER
        });
    }

    function _getAddress(string memory contractName) internal view returns (address) {
        return DevOpsTools.get_most_recent_deployment(contractName, block.chainid);
    }
}
