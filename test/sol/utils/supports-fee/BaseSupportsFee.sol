//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";

import {MockSupportsFee} from "../../../mocks/MockSupportsFee.sol";

abstract contract BaseSupportsFee is Base {
    MockSupportsFee internal _supportsFee;

    function setUp() public virtual override {
        super.setUp();

        _registry = new MockSupportsFee(_empty, );
    }
}
