//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Base} from "../../bases/Base.sol";
import {BaseUsesToken} from "../../bases/BaseUsesToken.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";

abstract contract BaseLens is Base, BaseUsesToken {
    MockStrategy[] internal _strategy;

    function setUp() public virtual override {
        super.setUp();

        _strategy = new MockStrategy(_token);

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(this));

        // address[] memory spender = new address[](1);
        // spender[0] = address(_strategy);
        // _approveAll(spender);
    }
}
