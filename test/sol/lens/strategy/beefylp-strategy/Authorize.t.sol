//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {BaseStrategy} from "./BaseStrategy.sol";
import {BaseImpersonate} from "../../../bases/BaseImpersonate.sol";

contract AuthorizeTest is BaseStrategy, BaseImpersonate {
    // Fail to deposit into the strategy due to lack of authorization.
    function testFailDeposit() public impersonate(vm, _empty) {
        _strategy.deposit(_tokenAmount);
    }

    // Fail to deposit all into the strategy due to lack of authorization.
    function testFailDepositAll() public impersonate(vm, _empty) {
        _strategy.depositAll();
    }

    // Fail to withdraw from the strategy due to lack of authorization.
    function testFailWithdraw() public impersonate(vm, _empty) {
        _strategy.withdraw(_tokenAmount);
    }

    // Fail to withdraw all from the strategy due to lack of authorization.
    function testFailWithdrawAll() public impersonate(vm, _empty) {
        _strategy.withdrawAll();
    }
}
