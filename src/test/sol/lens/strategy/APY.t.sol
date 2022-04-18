//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "@contracts/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is StrategyBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    BeefyLPStrategy private strategy;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
    }

    function testUpdateAPY() public {
        (uint256 initialAPY, uint256 decimals) = strategy.APY();

        uint256 newAPY = (Config.getInitialAPY() + 100) * 10**decimals;

        strategy.updateAPY(newAPY);

        (uint256 updatedAPY, ) = strategy.APY();

        assertTrue(updatedAPY != initialAPY);
        assertTrue(updatedAPY != newAPY);
    }
}
