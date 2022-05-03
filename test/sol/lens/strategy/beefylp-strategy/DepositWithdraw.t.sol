//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../../helpers/Config.sol";

contract DepositWithdrawTest is StrategyBase {
    using SafeMathUpgradeable for uint256;

    // Deposit and withdraw funds from the strategy.
    function testDepositWithdraw() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
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
            _assertApproxEq(balance[i], tokenAmount[i]);
        }

        // Calculate initial amount before withdraw
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        // Withdraw a safe amount to where the whole balance is not extracted
        uint256[] memory fosBalance = new uint256[](token.length);
        (uint256 fosPercent, uint256 fosDenominator) = _getFOS();
        for (uint256 i = 0; i < token.length; i++) fosBalance[i] = tokenAmount[i].mul(fosDenominator.sub(fosPercent)).div(fosDenominator);

        strategy.withdraw(fosBalance);

        for (uint256 i = 0; i < token.length; i++) _assertApproxEq(token[i].balanceOf(address(this)).sub(initialBalance[i]), fosBalance[i]);

        // Withdraw all tokens from the strategy
        strategy.withdrawAll();

        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(token[i].balanceOf(address(this)).sub(initialBalance[i]), balance[i]);

            assertEq(strategy.approxBalance(token[i]), 0);
        }
    }

    // Deposit and withdraw all funds from the strategy.
    function testDepositAllWithdrawAll() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();

        // Deposit all into the strategy and check the balance is what was deposited
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        strategy.depositAll();

        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(strategy.approxBalance(token[i]), initialBalance[i]);

            assertEq(token[i].balanceOf(address(this)), 0);
        }

        // Withdraw all tokens from the strategy
        strategy.withdrawAll();

        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(token[i].balanceOf(address(this)), initialBalance[i]);

            assertEq(strategy.approxBalance(token[i]), 0);
        }
    }

    // Deposit zero funds into the strategy.
    function testDepositZero() public {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmountZero = new uint256[](token.length);

        // Deposit zero and check no balances have been updated
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        strategy.deposit(tokenAmountZero);

        for (uint256 i = 0; i < token.length; i++) {
            assertEq(token[i].balanceOf(address(this)), initialBalance[i]);

            assertEq(strategy.approxBalance(token[i]), 0);
        }
    }

    // Withdraw zero funds from the strategy.
    function testWithdrawZero() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        uint256[] memory tokenAmountZero = new uint256[](token.length);

        // Withdraw zero when there are no tokens
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        strategy.withdraw(tokenAmountZero);

        for (uint256 i = 0; i < token.length; i++) assertEq(token[i].balanceOf(address(this)), initialBalance[i]);

        // Withdraw zero when there are some tokens
        strategy.deposit(tokenAmount);

        initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        strategy.withdraw(tokenAmountZero);

        for (uint256 i = 0; i < token.length; i++) assertEq(token[i].balanceOf(address(this)), initialBalance[i]);

        strategy.withdrawAll();
    }
}
