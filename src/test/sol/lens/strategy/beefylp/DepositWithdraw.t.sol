//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../../helpers/Config.sol";
import {AssertUtils} from "../../../helpers/AssertUtils.sol";
import {BeefyLPStrategy} from "../../../../../contracts/lens/strategy/BeefyLPStrategy.sol";

contract DepositWithdrawTest is StrategyBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    BeefyLPStrategy private strategy;

    uint256 private fosPercent;
    uint256 private fosDenominator;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();

        fosPercent = Config.getFosPercent();
        fosDenominator = Config.getFosDenominator();
    }

    // Deposit and withdraw funds from the strategy.
    function testDepositWithdraw() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit amount into the strategy
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        strategy.deposit(tokenAmount);

        // Check the balance is what was deposited
        uint256[] memory balance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) {
            assertEq(initialBalance[i].sub(token[i].balanceOf(address(this))), tokenAmount[i]);

            balance[i] = strategy.approxBalance(token[i]);
            AssertUtils.assertApproxEqual(balance[i], tokenAmount[i], fosPercent, fosDenominator);
        }

        // Calculate initial amount before withdraw
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        // Withdraw a safe amount to where the whole balance is not extracted
        uint256[] memory fosBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) fosBalance[i] = fosDenominator.sub(fosPercent).mul(tokenAmount[i]).div(fosDenominator);

        strategy.withdraw(fosBalance);

        for (uint256 i = 0; i < token.length; i++) assertEq(token[i].balanceOf(address(this)).sub(initialBalance[i]), fosBalance[i]);

        // Withdraw all tokens from the strategy
        strategy.withdrawAll();

        for (uint256 i = 0; i < token.length; i++) {
            AssertUtils.assertApproxEqual(token[i].balanceOf(address(this)).sub(initialBalance[i]), balance[i], fosPercent, fosDenominator);

            assertEq(strategy.approxBalance(token[i]), 0);
        }
    }

    // Deposit and withdraw all funds from the strategy.
    function testDepositAllWithdrawAll() public useFunds {
        IERC20[] memory token = Config.getToken();

        // Deposit all into the strategy and check the balance is what was deposited
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        strategy.depositAll();

        for (uint256 i = 0; i < token.length; i++) {
            AssertUtils.assertApproxEqual(strategy.approxBalance(token[i]), initialBalance[i], fosPercent, fosDenominator);

            assertEq(token[i].balanceOf(address(this)), 0);
        }

        // Withdraw all tokens from the strategy
        strategy.withdrawAll();

        for (uint256 i = 0; i < token.length; i++) {
            AssertUtils.assertApproxEqual(token[i].balanceOf(address(this)), initialBalance[i], fosPercent, fosDenominator);

            assertEq(strategy.approxBalance(token[i]), 0);
        }
    }

    /**
     * These below need to be updated because they should work now
     */

    // Deposit zero funds into the strategy.
    function testFailDepositZero() public {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = new uint256[](token.length);

        strategy.deposit(tokenAmount);
    }

    // Withdraw zero funds from the strategy.
    function testFailWithdrawZero() public {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = new uint256[](token.length);

        strategy.withdraw(tokenAmount);
    }
}
