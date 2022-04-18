//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../contracts/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is StrategyBase {
    using SafeMath for uint256;

    BeefyLPStrategy private strategy;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
    }

    // Test that updating the strategies APY works properly.
    function testUpdateAPY() public {
        (uint256 initialAPY, uint256 decimals) = strategy.APY();

        uint256 newAPY = Config.getInitialAPY().add(100).mul(10**decimals);

        strategy.updateAPY(newAPY);

        (uint256 updatedAPY, ) = strategy.APY();

        assertTrue(updatedAPY != initialAPY);
        assertTrue(updatedAPY != newAPY);
    }
}
