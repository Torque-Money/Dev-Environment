//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract LPoolCore is Initializable, AccessControlUpgradeable {
    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN_ROLE");
    bytes32 public constant POOL_APPROVED = keccak256("POOL_APPROVED_ROLE");

    address public converter;
    address public oracle;

    function initializeLPoolCore(address converter_, address oracle_) public initializer {
        __AccessControl_init();

        _setRoleAdmin(POOL_ADMIN, POOL_ADMIN);
        _setRoleAdmin(POOL_APPROVED, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());

        converter = converter_;
        oracle = oracle_;
    }

    // Set the converter to use
    function setConverter(address converter_) external onlyRole(POOL_ADMIN) {
        converter = converter_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyRole(POOL_ADMIN) {
        oracle = oracle_;
    }
}
