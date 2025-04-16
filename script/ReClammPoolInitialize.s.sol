// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {IRouter} from "@balancer-v3-monorepo/interfaces/vault/IRouter.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";
import {IVault} from "@balancer-v3-monorepo/interfaces/vault/IVault.sol";
import {IReClammPool} from "@reclamm/interfaces/IReClammPool.sol";

contract ReClammPoolInitialize is Script {
    IPermit2 public constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IRouter public constant router = IRouter(0x3f170631ed9821Ca51A59D996aB095162438DC10);
    IVault public constant vault = IVault(0xbA1333333333a1BA1108E8412f11850A5C319bA9);
    IReClammPool public constant pool = IReClammPool(0xde842Def79C17A52D7FB4b61c238D78fD18F11e6);
    IERC20 weth = IERC20(0x4200000000000000000000000000000000000006);
    IERC20 usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256 initialBalanceRatio = pool.computeInitialBalanceRatio();
        console.log("initialBalanceRatio", initialBalanceRatio);

        uint256 wethAmount = 0.00025e18;
        uint256 usdcAmount = wethAmount * initialBalanceRatio / 1e18 / 1e12;

        console.log("usdcAmount", usdcAmount);
        console.log("wethAmount", wethAmount);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = weth;
        tokens[1] = usdc;

        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[0] = wethAmount;
        exactAmountsIn[1] = usdcAmount;

        uint256 minBptAmountOut = 0;
        bool wethIsEth = false;
        bytes memory userData = "";

        usdc.approve(address(permit2), 100_000_000e18);
        permit2.approve(address(usdc), address(router), type(uint160).max, type(uint48).max);

        weth.approve(address(permit2), 100_000_000e18);
        permit2.approve(address(weth), address(router), type(uint160).max, type(uint48).max);

        router.initialize(address(pool), tokens, exactAmountsIn, minBptAmountOut, wethIsEth, userData);
        vm.stopBroadcast();
    }
}
