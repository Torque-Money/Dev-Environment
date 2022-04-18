//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "@contracts/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is StrategyBase {
    BeefyLPStrategy strategy;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
    }

    function testDepositWithdraw() public {}

    function testDepositAllWithdrawAll() public {}
}
