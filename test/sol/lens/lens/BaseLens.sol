//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";
import {BaseUsesToken} from "../../bases/BaseUsesToken.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";

abstract contract BaseLens is Base, BaseUsesToken {
    MockStrategy[] internal _strategy;

    function setUp() public virtual override(Base, BaseUsesToken) {
        Base.setUp();
        BaseUsesToken.setUp();

        _strategy = new MockStrategy[](2);
        _strategy[0] = new MockStrategy(_token);
        _strategy[1] = new MockStrategy(_token);

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(this));
    }
}
