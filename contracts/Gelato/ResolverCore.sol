//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract ResolverCore is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public RESOLVER_ADMIN;

    address public taskTreasury;
    address public depositReceiver;
    address public ethAddress;

    address public converter;
    address public marginLong;

    function initializeResolverCore(
        address taskTreasury_,
        address depositReceiver_,
        address ethAddress_,
        address marginLong_,
        address converter_
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();

        RESOLVER_ADMIN = keccak256("RESOLVER_ADMIN_ROLE");
        _setRoleAdmin(RESOLVER_ADMIN, RESOLVER_ADMIN);
        _grantRole(RESOLVER_ADMIN, _msgSender());

        taskTreasury = taskTreasury_;
        depositReceiver = depositReceiver_;
        ethAddress = ethAddress_;
        marginLong = marginLong_;
        converter = converter_;
    }

    // Pause the contract
    function pause() external onlyRole(RESOLVER_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(RESOLVER_ADMIN) {
        _unpause();
    }

    // Set the task treasury to use
    function setTaskTreasury(address taskTreasury_) external onlyRole(RESOLVER_ADMIN) {
        taskTreasury = taskTreasury_;
    }

    // Set the deposit receiver
    function setDepositReceiver(address depositReceiver_) external onlyRole(RESOLVER_ADMIN) {
        depositReceiver = depositReceiver_;
    }

    // Set the eth address
    function setEthAddress(address ethAddress_) external onlyRole(RESOLVER_ADMIN) {
        ethAddress = ethAddress_;
    }

    // Set the converter to use
    function setConverter(address converter_) external onlyRole(RESOLVER_ADMIN) {
        converter = converter_;
    }

    // Set the margin long to use
    function setMarginLong(address marginLong_) external onlyRole(RESOLVER_ADMIN) {
        marginLong = marginLong_;
    }

    receive() external payable {}
}
