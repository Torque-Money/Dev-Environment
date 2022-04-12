//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";


contract TorqueTAU is Initializable, AccessControlEnumerableUpgradeable, ERC20Upgradeable {
    // **** I want to create some seperate roles here for minter and burner and admin

    function initialize() external initializer {
        __ERC20_init("Torque TAU", "TAU");
        __AccessControlEnumerable_init();

        // **** Now I need to configure roles here for minter, burner, and token admin
    }


}
