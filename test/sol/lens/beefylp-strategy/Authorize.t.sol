//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {StrategyBase} from "./StrategyBase.sol";
import {Impersonate} from "../../helpers/Impersonate.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../src/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is StrategyBase, Impersonate {
    using SafeMathUpgradeable for uint256;

    BeefyLPStrategy private strategy;
    address private empty;
    ICheatCodes private cheats;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
        empty = _getEmpty();
        cheats = _getCheats();
    }

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

    // Fail to update the strategies APY.
    function testFailUpdateAPY() public impersonate(empty) {
        strategy.updateAPY(Config.getInitialAPY());
    }

    function _getCheats() internal view override(StrategyBase, Impersonate) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
