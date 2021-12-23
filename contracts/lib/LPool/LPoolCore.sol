//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract LPoolCore is AccessControl {
    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN");
    bytes32 public constant POOL_APPROVED = keccak256("POOL_APPROVED");

    struct StakingPeriod {
        uint256 totalDeposited;
        uint256 liquidity;
        mapping(address => uint256) deposits;

        uint256 totalClaimed;
        mapping(address => uint256) claims;
    }

    constructor() {
        _setRoleAdmin(POOL_APPROVED, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());
    }
}