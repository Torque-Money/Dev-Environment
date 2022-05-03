//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {EmergencyBase} from "./EmergencyBase.sol";
import {Impersonate} from "../../helpers/Impersonate.sol";

import {MockEmergency} from "../../../mocks/MockEmergency.sol";
import {Config} from "../../helpers/Config.sol";

contract Authorize is EmergencyBase, Impersonate {
    MockEmergency private emergency;
    address private empty;

    function setUp() public override {
        super.setUp();

        emergency = _getEmergency();
        empty = _getEmpty();
    }

    // Check that an approved account will be able to use emergency withdraw
    function testAuthorized() public {
        IERC20Upgradeable[] memory token = Config.getToken();
        emergency.inCaseTokensGetStuck(token[0], 0);
    }

    // Check that a non approved account will not be able to use an emergency withdraw
    function testFailUnauthorized() public impersonate(empty) {
        IERC20Upgradeable[] memory token = Config.getToken();
        emergency.inCaseTokensGetStuck(token[0], 0);
    }

    function _getCheats() internal view virtual override(EmergencyBase, Impersonate) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
