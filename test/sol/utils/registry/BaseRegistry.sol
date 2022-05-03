//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";

import {MockRegistry} from "../../../mocks/MockRegistry.sol";

abstract contract BaseRegistry is Base {
    MockRegistry internal _registry;

    function setUp() public virtual override {
        super.setUp();

        _registry = new MockRegistry();
    }
}
