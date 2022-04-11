//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract MarginCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public MARGIN_ADMIN;

    address public pool;
    address public oracle;

    function initializeMarginCore(address pool_, address oracle_) public initializer {
        __AccessControl_init();
        __Pausable_init();

        MARGIN_ADMIN = keccak256("MARGIN_ADMIN_ROLE");
        _setRoleAdmin(MARGIN_ADMIN, MARGIN_ADMIN);
        _grantRole(MARGIN_ADMIN, _msgSender());

        pool = pool_;
        oracle = oracle_;
    }

    // Pause the contract
    function pause() external onlyRole(MARGIN_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(MARGIN_ADMIN) {
        _unpause();
    }

    // Set the pool to use
    function setPool(address pool_) external onlyRole(MARGIN_ADMIN) {
        pool = pool_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyRole(MARGIN_ADMIN) {
        oracle = oracle_;
    }
}
