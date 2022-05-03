//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {BaseEmergency} from "./BaseEmergency.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

import {Config} from "../../helpers/Config.sol";

contract Authorize is BaseEmergency, BaseImpersonate {
    // Check that an approved account will be able to use an admin function
    function testAuthorized() public {
        IERC20Upgradeable[] memory token = Config.getToken();
        _emergency.inCaseTokensGetStuck(token[0], 0);
    }

    // Check that a non approved account will not be able to use an admin function
    function testFailUnauthorized() public impersonate(vm, _empty) {
        IERC20Upgradeable[] memory token = Config.getToken();
        _emergency.inCaseTokensGetStuck(token[0], 0);
    }
}
