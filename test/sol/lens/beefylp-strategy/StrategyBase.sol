//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {Base} from "../../helpers/Base.sol";
import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../src/lens/strategy/BeefyLPStrategy.sol";

contract StrategyBase is Base, UsesTokenBase {
    BeefyLPStrategy private strategy;

    function setUp() public virtual override {
        super.setUp();

        strategy = new BeefyLPStrategy();
        strategy.initialize(Config.getToken(), Config.getUniRouter(), Config.getUniFactory(), Config.getBeefyVault());

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(strategy);
        _approveAll(spender);
    }

    function _getStrategy() internal view returns (BeefyLPStrategy _strategy) {
        return strategy;
    }

    function _getCheats() internal view virtual override(Base, UsesTokenBase) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
