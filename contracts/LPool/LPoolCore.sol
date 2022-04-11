//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract LPoolCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public POOL_ADMIN;

    address public converter;
    address public oracle;

    function initializeLPoolCore(address converter_, address oracle_) public initializer {
        __AccessControl_init();
        __Pausable_init();

        POOL_ADMIN = keccak256("POOL_ADMIN_ROLE");
        _setRoleAdmin(POOL_ADMIN, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());

        converter = converter_;
        oracle = oracle_;
    }

    // Pause the contract
    function pause() external onlyRole(POOL_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(POOL_ADMIN) {
        _unpause();
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
