//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {SupportsTokenUpgradeable} from "../../src/utils/SupportsTokenUpgradeable.sol";

contract MockSupportsToken is Initializable, SupportsTokenUpgradeable {
    constructor(IERC20Upgradeable[] memory token) {
        _initialize(token);
    }

    function _initialize(IERC20Upgradeable[] memory token) internal initializer {
        __SupportsToken_init(token);
    }
}
