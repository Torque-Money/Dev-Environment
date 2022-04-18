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

    function testDepositWithdraw() public useFunds {
        // **** First we need to deposit the given amount of tokens into the strategy and see what happens
    }

    function testDepositAllWithdrawAll() public useFunds {}
}
