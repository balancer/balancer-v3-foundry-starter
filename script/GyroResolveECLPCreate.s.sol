// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IGyroECLPPool} from "@balancer-v3-monorepo/interfaces/pool-gyro/IGyroECLPPool.sol";
import {TokenConfig, PoolRoleAccounts, TokenType} from "@balancer-v3-monorepo/interfaces/vault/VaultTypes.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IRateProvider} from "@balancer-v3-monorepo/interfaces/solidity-utils/helpers/IRateProvider.sol";
import {IRouter} from "@balancer-v3-monorepo/interfaces/vault/IRouter.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

/**
 * Run script (in simulation mode):
 * forge script script/GyroResolveECLPCreate.s.sol:GyroResolveECLPCreate --rpc-url sepolia
 * 
 * Run script (in broadcast mode):
 * forge script script/GyroResolveECLPCreate.s.sol:GyroResolveECLPCreate --rpc-url sepolia --broadcast
 */
interface IGyroECLPPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        TokenConfig[] memory tokens,
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams,
        PoolRoleAccounts memory roleAccounts,
        uint256 swapFeePercentage,
        address poolHooksContract,
        bool enableDonation,
        bool disableUnbalancedLiquidity,
        bytes32 salt
    ) external returns (address pool);

    function getPoolCount() external view returns (uint256);
}

contract GyroResolveECLPCreate is Script {
    IPermit2 public constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IRouter public constant router = IRouter(0x5e315f96389C1aaF9324D97d3512ae1e0Bf3C21a); // sepolia
    IGyroECLPPoolFactory poolFactory = IGyroECLPPoolFactory(0x589cA6855C348d831b394676c25B125BcdC7F8ce); // sepolia
    // IRouter public constant router = IRouter(0xAE563E3f8219521950555F5962419C8919758Ea2); // mainnet
    // IGyroECLPPoolFactory poolFactory = IGyroECLPPoolFactory(0xE9B0a3bc48178D7FE2F5453C8bc1415d73F966d0); // mainnet


    IERC20 wstUSR = IERC20(0x0f409E839a6A790aecB737E4436293Be11717f95); // sepolia beets
    IERC20 rlp = IERC20(0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75); // sepolia bal
    // IERC20 wstUSR = IERC20(0x1202F5C7b4B9E47a1A484E8B270be34dbbC75055); // mainnet
    // IERC20 rlp = IERC20(0x4956b52aE2fF65D74CA2d61207523288e4528f96); // mainnet

    function run() public {
        // Add .env in root with PRIVATE_KEY
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // option to choose a pause & swap fee manager
        PoolRoleAccounts memory roleAccounts;
        roleAccounts.pauseManager = 0x0000000000000000000000000000000000000000;
        roleAccounts.swapFeeManager = 0x0000000000000000000000000000000000000000;
        
        TokenConfig memory t0;
        t0.token = wstUSR;
        t0.tokenType = TokenType.WITH_RATE;
        t0.rateProvider = IRateProvider(0x34101091673238545De8a846621823D9993c3085); // sepolia stataEthUSDC rate provider
        // t0.rateProvider = IRateProvider(0x100ab8fb135a76d1014f529041F35a1a9e6c78a2); // mainnet
        t0.paysYieldFees = true;

        TokenConfig memory t1;
        t1.token = rlp;
        t1.tokenType = TokenType.WITH_RATE;
        t1.rateProvider = IRateProvider(0x22DB61f3A8d81d3D427a157fdAe8c7EB5b5fD373); // sepolia stataEthDAI rate provider
        // t1.rateProvider = IRateProvider(0x4017F109CF5583D68A6E213CC65f609Cd12791E6); // mainnet
        t1.paysYieldFees = true;

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0] = t0;
        tokenConfigs[1] = t1;
    
        IGyroECLPPool.EclpParams memory eclpParams;
        eclpParams.alpha = 980000000000000000;
        eclpParams.beta = 1007000000000000000;
        eclpParams.c = 707283579973402312;
        eclpParams.s = 706929938183415611;
        eclpParams.lambda = 500000000000000000000;

        // example derived params were calculted using typescript SDK helper function
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams;
        derivedEclpParams.tauAlpha.x = -98000611417254585354938420274489260778;
        derivedEclpParams.tauAlpha.y = 19896737467340474059784953456410754810;
        derivedEclpParams.tauBeta.x = 88171788866808887695581019012009233830;
        derivedEclpParams.tauBeta.y = 47177702869330934547324824706142381471;
        derivedEclpParams.u = 93086188500437376891500787340988255394;
        derivedEclpParams.v = 33530398221925082342472646045686671848;
        derivedEclpParams.w = 13640480995082149332806370654887099284;
        derivedEclpParams.z = -4867856539378270432555214623661648118;
        derivedEclpParams.dSq = 100000000000000000108254687936544866500;

        // deploy the pool contract via the factory
        address pool = poolFactory.create(
            "Gyroscope ECLP RLP/wstUSR", // name
            "ECLP-RLP-wstUSR", // symbol
            sortTokenConfig(tokenConfigs),
            eclpParams,
            derivedEclpParams,
            roleAccounts,
            500000000000000, // swapFeePercentage (0.05%)
            address(0), // poolHooksContract
            false, // enableDonation
            false, // disableUnbalancedLiquidity
            bytes32(block.number) // salt (must be different for each pool deployed with same params)
        );
        console.log("pool address:", pool);

        // approve permit2 contract as spender on token contracts
        wstUSR.approve(address(permit2), type(uint256).max);
        rlp.approve(address(permit2), type(uint256).max);

        // approve router as spender on permit2 contract
        permit2.approve(address(wstUSR), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(rlp), address(router), type(uint160).max, type(uint48).max);

        // initialize the pool via the router contract
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = wstUSR;
        tokens[1] = rlp;

        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[0] = 0.1e18;
        exactAmountsIn[1] = 0.1e18;
        uint256 minBptAmount = 0;

        router.initialize(pool, tokens, exactAmountsIn, minBptAmount, false, bytes(""));

        vm.stopBroadcast();
    }

    function sortTokenConfig(TokenConfig[] memory tokenConfig) public pure returns (TokenConfig[] memory) {
        for (uint256 i = 0; i < tokenConfig.length - 1; ++i) {
            for (uint256 j = 0; j < tokenConfig.length - i - 1; j++) {
                if (tokenConfig[j].token > tokenConfig[j + 1].token) {
                    // Swap if they're out of order.
                    (tokenConfig[j], tokenConfig[j + 1]) = (tokenConfig[j + 1], tokenConfig[j]);
                }
            }
        }

        return tokenConfig;
    }
}
