//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {ILens} from "../../interfaces/lens/ILens.sol";
import {RegistryUpgradeable} from "../../utils/RegistryUpgradeable.sol";

import {IVault} from "../../interfaces/lens/IVault.sol";
import {IStrategy} from "../../interfaces/lens/IStrategy.sol";

contract Lens is Initializable, AccessControlUpgradeable, ILens, RegistryUpgradeable {
    bytes32 public LENS_ADMIN_ROLE;
    bytes32 public LENS_CONTROLLER_ROLE;

    IVault private vault;

    function initialize(IVault _vault) external initializer {
        __AccessControl_init();
        __Registry_init();

        LENS_ADMIN_ROLE = keccak256("LENS_ADMIN_ROLE");
        _setRoleAdmin(LENS_ADMIN_ROLE, LENS_ADMIN_ROLE);
        _grantRole(LENS_ADMIN_ROLE, _msgSender());

        LENS_CONTROLLER_ROLE = keccak256("LENS_CONTROLLER_ROLE");
        _setRoleAdmin(LENS_CONTROLLER_ROLE, LENS_ADMIN_ROLE);

        vault = _vault;
    }

    // Get the vault used by the controller.
    function getVault() external view override returns (IVault _vault) {
        return vault;
    }

    // Update the vaults strategy
    function update(IStrategy strategy) external override onlyRole(LENS_CONTROLLER_ROLE) onlyEntry(address(strategy)) {
        vault.setStrategy(strategy);
    }
}
