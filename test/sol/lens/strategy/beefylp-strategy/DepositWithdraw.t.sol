//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {BaseStrategy} from "./BaseStrategy.sol";

import {Config} from "../../../helpers/Config.sol";

contract DepositWithdrawTest is BaseStrategy {
    using SafeMathUpgradeable for uint256;

    // Deposit and withdraw funds from the strategy.
    function testDepositWithdraw() public useFunds(vm) {
        // Deposit amount into the strategy
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        _strategy.deposit(_tokenAmount);

        // Check the balance is what was deposited
        uint256[] memory balance = new uint256[](_token.length);
        for (uint256 i = 0; i < token.length; i++) {
            assertEq(initialBalance[i].sub(_token[i].balanceOf(address(this))), _tokenAmount[i]);

            balance[i] = _strategy.approxBalance(_token[i]);
            _assertApproxEq(balance[i], _tokenAmount[i]);
        }

        // Calculate initial amount before withdraw
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        // Withdraw a safe amount to where the whole balance is not extracted
        uint256[] memory fosBalance = new uint256[](_token.length);
        (uint256 fosPercent, uint256 fosDenominator) = Config.getFos();
        for (uint256 i = 0; i < _token.length; i++) fosBalance[i] = _tokenAmount[i].mul(fosDenominator.sub(fosPercent)).div(fosDenominator);

        _strategy.withdraw(fosBalance);

        for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(_token[i].balanceOf(address(this)).sub(initialBalance[i]), fosBalance[i]);

        // Withdraw all tokens from the strategy
        _strategy.withdrawAll();

        for (uint256 i = 0; i < _token.length; i++) {
            _assertApproxEq(_token[i].balanceOf(address(this)).sub(initialBalance[i]), balance[i]);

            assertEq(_strategy.approxBalance(_token[i]), 0);
        }
    }

    // Deposit and withdraw all funds from the strategy.
    function testDepositAllWithdrawAll() public useFunds(vm) {
        // Deposit all into the strategy and check the balance is what was deposited
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        _strategy.depositAll();

        for (uint256 i = 0; i < _token.length; i++) {
            _assertApproxEq(_strategy.approxBalance(_token[i]), initialBalance[i]);

            assertEq(_token[i].balanceOf(address(this)), 0);
        }

        // Withdraw all tokens from the strategy
        _strategy.withdrawAll();

        for (uint256 i = 0; i < _token.length; i++) {
            _assertApproxEq(_token[i].balanceOf(address(this)), initialBalance[i]);

            assertEq(_strategy.approxBalance(_token[i]), 0);
        }
    }

    // Deposit zero funds into the strategy.
    function testDepositZero() public {
        uint256[] memory tokenAmountZero = new uint256[](_token.length);

        // Deposit zero and check no balances have been updated
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        _strategy.deposit(tokenAmountZero);

        for (uint256 i = 0; i < _token.length; i++) {
            assertEq(_token[i].balanceOf(address(this)), initialBalance[i]);

            assertEq(_strategy.approxBalance(_token[i]), 0);
        }
    }

    // Withdraw zero funds from the strategy.
    function testWithdrawZero() public useFunds(vm) {
        uint256[] memory tokenAmountZero = new uint256[](_token.length);

        // Withdraw zero when there are no tokens
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        _strategy.withdraw(tokenAmountZero);

        for (uint256 i = 0; i < _token.length; i++) assertEq(_token[i].balanceOf(address(this)), initialBalance[i]);

        // Withdraw zero when there are some tokens
        _strategy.deposit(tokenAmount);

        initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        _strategy.withdraw(tokenAmountZero);

        for (uint256 i = 0; i < _token.length; i++) assertEq(_token[i].balanceOf(address(this)), initialBalance[i]);

        _strategy.withdrawAll();
    }
}
