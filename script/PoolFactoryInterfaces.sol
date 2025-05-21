// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {TokenConfig, PoolRoleAccounts} from "@balancer-v3-monorepo/interfaces/vault/VaultTypes.sol";
import {IGyroECLPPool} from "@balancer-v3-monorepo/interfaces/pool-gyro/IGyroECLPPool.sol";

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
