//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {Config} from "../../helpers/Config.sol";
import {Empty} from "../../helpers/Empty.sol";
import {BeefyLPStrategy} from "../../../../contracts/lens/strategy/BeefyLPStrategy.sol";

contract StrategyBase is DSTest, UsesTokenBase {
    ICheatCodes private cheats;
    address private empty;
    BeefyLPStrategy private strategy;

    function setUp() public virtual {
        empty = address(new Empty());

        cheats = Config.getCheatCodes();

        strategy = new BeefyLPStrategy();
        strategy.initialize(Config.getToken(), Config.getInitialAPY(), Config.getUniRouter(), Config.getUniFactory(), Config.getBeefyVault());

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(strategy);
        _approveAll(spender);
    }

    function _getEmpty() internal view returns (address _empty) {
        return empty;
    }

    function _getStrategy() internal view returns (BeefyLPStrategy _strategy) {
        return strategy;
    }

    function _getCheats() internal view returns (ICheatCodes _cheats) {
        return cheats;
    }
}
