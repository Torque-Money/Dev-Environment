//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract LPoolCore is AccessControl {
    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN_ROLE");
    bytes32 public constant POOL_APPROVED = keccak256("POOL_APPROVED_ROLE");

    constructor() {
        _setRoleAdmin(POOL_ADMIN, POOL_ADMIN);
        _setRoleAdmin(POOL_APPROVED, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());
    }
}