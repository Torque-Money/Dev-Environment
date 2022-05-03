//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseStrategy} from "./BaseStrategy.sol";
import {BaseImpersonate} from "../../../bases/BaseImpersonate.sol";

import {Config} from "../../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../../src/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is BaseStrategy, BaseImpersonate {
    // Fail to deposit into the strategy due to lack of authorization.
    function testFailDeposit() public impersonate(empty) {
        strategy.deposit(Config.getTokenAmount());
    }

    // Fail to deposit all into the strategy due to lack of authorization.
    function testFailDepositAll() public impersonate(empty) {
        strategy.depositAll();
    }

    // Fail to withdraw from the strategy due to lack of authorization.
    function testFailWithdraw() public impersonate(empty) {
        strategy.withdraw(Config.getTokenAmount());
    }

    // Fail to withdraw all from the strategy due to lack of authorization.
    function testFailWithdrawAll() public impersonate(empty) {
        strategy.withdrawAll();
    }
}
