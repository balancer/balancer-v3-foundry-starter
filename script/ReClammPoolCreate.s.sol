// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IBufferRouter} from "@balancer-v3-monorepo/interfaces/vault/IBufferRouter.sol";
import {TokenConfig, PoolRoleAccounts, TokenType} from "@balancer-v3-monorepo/interfaces/vault/VaultTypes.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";
import {IRateProvider} from "@balancer-v3-monorepo/interfaces/solidity-utils/helpers/IRateProvider.sol";
/**
 * To run against a local fork, start anvil:
 * `$ anvil --fork-url RPC_URL
 * Run script (in simulation mode):
 * `$ forge script script/StableSurgeCreate.s.sol:StableSurgeCreate --fork-url http://localhost:8545
 */

interface IReClammPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        TokenConfig[] memory tokens,
        PoolRoleAccounts memory roleAccounts,
        uint256 swapFeePercentage,
        uint256 initialMinPrice,
        uint256 initialMaxPrice,
        uint256 initialTargetPrice,
        uint256 priceShiftDailyRate,
        uint64 centerednessMargin,
        bytes32 salt
    ) external returns (address pool);
    function getPoolCount() external view returns (uint256);
}

contract ReClammPoolCreate is Script {
    IReClammPoolFactory poolFactory = IReClammPoolFactory(0x0f08eEf2C785AA5e7539684aF04755dEC1347b7c);

    IERC20 weth = IERC20(0x4200000000000000000000000000000000000006);
    IERC20 usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

    function run() public returns (uint256) {
        // Add .env in root with PRIVATE_KEY
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.logUint(poolFactory.getPoolCount());

        PoolRoleAccounts memory roleAccounts;
        // beets deployer address, change to your own address, or remove completely to delegate to bal dao
        roleAccounts.pauseManager = 0xb5e6b895734409Df411a052195eb4EE7e40d8696;
        roleAccounts.swapFeeManager = 0xb5e6b895734409Df411a052195eb4EE7e40d8696;

        TokenConfig memory t1;
        t1.token = weth;
        t1.tokenType = TokenType.STANDARD;
        TokenConfig memory t2;

        t2.token = usdc;
        t2.tokenType = TokenType.STANDARD;
        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0] = t1;
        tokenConfigs[1] = t2;

        address newPool = poolFactory.create(
            "ReClamm weth/usdc", // Name
            "RECLAMM-WETH-USDC", // Symbol
            tokenConfigs, // tokens
            roleAccounts, // roleAccounts
            0.001e18, // 0.1% swapFeePercentage
            1500e18, // 1500 initialMinPrice
            1800e18, // 1800 initialMaxPrice
            1650e18, // 1650 initialTargetPrice
            1e18, // 100% priceShiftDailyRate
            0.2e18, // 20% centerednessMargin
            bytes32("salt1")
        );

        console.log(newPool);

        console.logUint(poolFactory.getPoolCount());

        vm.stopBroadcast();

        return 0;
    }
}
