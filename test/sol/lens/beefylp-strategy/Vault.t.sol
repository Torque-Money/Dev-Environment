//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {BeefyLPStrategy} from "../../../../src/lens/strategy/BeefyLPStrategy.sol";
import {TorqueVaultV1} from "../../../../src/lens/vault/TorqueVaultV1.sol";

contract VaultTest is StrategyBase {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    TorqueVaultV1 private vault;
    BeefyLPStrategy private strategy;
    address private empty;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
        empty = _getEmpty();

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), strategy, _getEmpty(), 0, 1000);

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(vault);
        _approveAll(spender);
    }

    // Test a deposit and redeem with the vault and Beefy LP strategy.
    function testDepositRedeem() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds into the vault
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        uint256 shares = vault.deposit(tokenAmount);

        // Check the balances of the vault and the user
        for (uint256 i = 0; i < token.length; i++) {
            assertEq(initialBalance[i].sub(token[i].balanceOf(address(this))), tokenAmount[i]);

            _assertApproxEq(vault.approxBalance(token[i]), tokenAmount[i]);
        }

        // Withdraw funds and check the balances
        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(token[i].balanceOf(address(this)), initialBalance[i]);
            _assertApproxEq(out[i], tokenAmount[i]);

            _assertApproxEq(vault.approxBalance(token[i]), 0);
        }
    }

    // Test the flow of funds between the vault and the strategy
    function testFundFlow() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds
        uint256 shares = vault.deposit(tokenAmount);

        // Check that vault has been allocated the correct amount of tokens and they have flowed into the right contracts
        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(vault.approxBalance(token[i]), tokenAmount[i]);
            _assertApproxEq(token[i].balanceOf(address(vault)), 0);

            _assertApproxEq(strategy.approxBalance(token[i]), tokenAmount[i]);
        }

        vault.redeem(shares);
    }

    // Eject vault funds from the strategy
    function testEjectAll() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds
        uint256 shares = vault.deposit(tokenAmount);

        // Eject funds
        vault.withdrawAllFromStrategy();

        // Check that the vault has been updated with tokens and the strategy has been emptied
        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(vault.approxBalance(token[i]), tokenAmount[i]);
            _assertApproxEq(token[i].balanceOf(address(vault)), tokenAmount[i]);

            _assertApproxEq(strategy.approxBalance(token[i]), 0);
        }

        // Check that the funds correctly flow back
        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) _assertApproxEq(out[i], tokenAmount[i]);
    }

    // Inject vault funds into the strategy.
    function testInjectAll() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds
        uint256 shares = vault.deposit(tokenAmount);

        // Eject funds
        vault.withdrawAllFromStrategy();

        // Inject funds
        vault.depositAllIntoStrategy();

        // Check that the vault has been updated with tokens and the strategy has been emptied
        for (uint256 i = 0; i < token.length; i++) {
            _assertApproxEq(vault.approxBalance(token[i]), tokenAmount[i]);
            _assertApproxEq(token[i].balanceOf(address(vault)), 0);

            _assertApproxEq(strategy.approxBalance(token[i]), tokenAmount[i]);
        }

        // Check that the funds correctly flow back
        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) _assertApproxEq(out[i], tokenAmount[i]);
    }
}
