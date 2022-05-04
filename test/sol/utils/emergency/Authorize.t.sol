//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {BaseEmergency} from "./BaseEmergency.sol";
import {BaseImpersonate} from "../../bases/BaseImpersonate.sol";

import {Config} from "../../helpers/Config.sol";

contract AuthorizeTest is BaseEmergency, BaseImpersonate {
    // Check that unauthorized users cant withdraw stuck funds
    function testFailWithdraw() public impersonate(vm, _empty) {
        IERC20Upgradeable[] memory token = Config.getToken();
        _emergency.inCaseTokensGetStuck(token[0], 0);
    }
}
