//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {IRegistry} from "../interfaces/utils/IRegistry.sol";

contract Registry is Initializable, AccessControlUpgradeable, IRegistry {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public REGISTRY_ADMIN_ROLE;

    EnumerableSet.AddressSet private _set;

    function __Registry_init() internal onlyInitializing {
        __AccessControl_init();

        __Registry_init_unchained();
    }

    function __Registry_init_unchained() internal onlyInitializing {
        REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);
        _grantRole(REGISTRY_ADMIN_ROLE, _msgSender());
    }

    function add(address entry) external virtual override onlyRole(REGISTRY_ADMIN_ROLE) {
        require(_set.add(entry), "Registry: Cannot add element to registry");
    }

    function remove(address entry) external virtual override onlyRole(REGISTRY_ADMIN_ROLE) {
        require(_set.remove(entry), "Registry: Cannot remove element from registry");
    }

    function isEntry(address entry) public view virtual override returns (bool _entry) {
        return _set.contains(entry);
    }

    function entryCount() public view virtual override returns (uint256 count) {
        return _set.length();
    }

    function entryByIndex(uint256 index) public view virtual override returns (address entry) {
        return _set.at(index);
    }
}
