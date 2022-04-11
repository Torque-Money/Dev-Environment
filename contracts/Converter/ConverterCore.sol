//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract ConverterCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public CONVERTER_ADMIN;

    address public router;

    function initializeConverterCore(address router_) public initializer {
        __AccessControl_init();
        __Pausable_init();

        CONVERTER_ADMIN = keccak256("CONVERTER_ADMIN_ROLE");
        _setRoleAdmin(CONVERTER_ADMIN, CONVERTER_ADMIN);
        _grantRole(CONVERTER_ADMIN, _msgSender());

        router = router_;
    }

    // Pause the contract
    function pause() external onlyRole(CONVERTER_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(CONVERTER_ADMIN) {
        _unpause();
    }

    // Set the router to be used
    function setRouter(address router_) external onlyRole(CONVERTER_ADMIN) {
        router = router_;
    }

    receive() external payable {}
}
