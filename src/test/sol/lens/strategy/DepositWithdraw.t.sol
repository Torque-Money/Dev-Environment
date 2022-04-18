//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "@contracts/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is StrategyBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    BeefyLPStrategy strategy;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
    }

    // Check if two numbers are equal off of a given percentage
    function _approxEqual(
        uint256 a,
        uint256 b,
        uint256 percent,
        uint256 denominator
    ) private {
        require(denominator != 0, "DepositWithdrawTest: Denominator cannot equal 0");
        require(percent <= denominator, "DepositWithdrawTest: Percent cannot be greater than denominator");

        uint256 max = Math.max(a, b);
        uint256 min = Math.min(a, b);

        uint256 compPercent = denominator.sub(percent);

        assertGt(a.mul(denominator), compPercent.mul(b));
    }

    function testDepositWithdraw() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit amount into the strategy
        uint256[] memory initialAmount = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialAmount[i] = token[i].balanceOf(address(this));

        strategy.deposit(tokenAmount);

        for (uint256 i = 0; i < token.length; i++) assertEq(initialAmount[i].sub(token[i].balanceOf(address(this))), tokenAmount[i]);

        // Check the balance is what was deposited
        for (uint256 i = 0; i < token.length; i++) _approxEqual(strategy.balance(token[i]), tokenAmount[i], 1, 1000);

        // Withdraw the given amounts and check what was withdrawn is equivalent (MAYBE NEEDS TO RETURN AMOUNTS)
    }

    function testDepositAllWithdrawAll() public useFunds {}
}
