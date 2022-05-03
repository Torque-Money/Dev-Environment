//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {EmergencyBase} from "./EmergencyBase.sol";
import {Impersonate} from "../../helpers/Impersonate.sol";

import {Config} from "../../helpers/Config.sol";
import {MockEmergency} from "../../../mocks/MockEmergency.sol";

contract Withdraw is EmergencyBase, Impersonate {
    MockEmergency private emergency;

    function setUp() public virtual override {
        super.setUp();
    }

    // **** This function needs to be able to attempt to withdraw ETH and tokens from the required contract
    // **** Speaking of which, how am I going to fund this account with the ETH that I want to fund it with ???

    function _getCheats() internal view virtual override(EmergencyBase, Impersonate) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
