//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {EmergencyBase} from "./EmergencyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {MockEmergency} from "../../../mocks/MockEmergency.sol";

contract Withdraw is EmergencyBase {
    MockEmergency private emergency;

    function setUp() public virtual override {
        super.setUp();

        emergency = _getEmergency();
    }

    // Test that an ERC20 token is withdrawable

    // Test that ETH is withdrawable

    function _getCheats() internal view virtual override returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
