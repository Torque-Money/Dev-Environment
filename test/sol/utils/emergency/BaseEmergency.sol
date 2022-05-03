//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseUsesToken} from "../../bases/BaseUsesToken.sol";
import {Base} from "../../bases/Base.sol";

import {MockEmergency} from "../../../mocks/MockEmergency.sol";

abstract contract BaseEmergency is Base, BaseUsesToken {
    MockEmergency internal _emergency;

    function setUp() public virtual override {
        super.setUp();

        _emergency = new MockEmergency();
    }
}
