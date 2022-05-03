//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {Base} from "../../helpers/Base.sol";
import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {MockEmergency} from "../../../mocks/MockEmergency.sol";

contract EmergencyBase is Base, UsesTokenBase {
    MockEmergency private emergency;

    function setUp() public override {
        super.setUp();

        emergency = new MockEmergency();
    }

    function _getEmergency() internal view returns (MockEmergency _emergency) {
        return emergency;
    }

    function _getCheats() internal view virtual override(Base, UsesTokenBase) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }

    function _getETHAddress() internal pure returns (address ETHAddress) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}
