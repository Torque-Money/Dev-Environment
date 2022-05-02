//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {Base} from "../../helpers/Base.sol";
import {EmergencyUpgradeable} from "../../../../src/utils/EmergencyUpgradeable.sol";

contract EmergencyBase is Base {
    EmergencyUpgradeable private emergency;

    function setUp() public override {
        super.setUp();

        emergency = new EmergencyUpgradeable();
        emergency.__Emergency_init();
    }

    function _getEmergency() internal view returns (EmergencyUpgradeable _emergency) {
        return emergency;
    }

    function _getCheats() internal view virtual override returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
