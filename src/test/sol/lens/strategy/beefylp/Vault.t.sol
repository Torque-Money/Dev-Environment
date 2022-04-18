//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {StrategyBase} from "./StrategyBase.sol";

import {Config} from "../../../helpers/Config.sol";
import {AssertUtils} from "../../../helpers/AssertUtils.sol";
import {BeefyLPStrategy} from "../../../../../contracts/lens/strategy/BeefyLPStrategy.sol";
import {TorqueVaultV1} from "../../../../../contracts/lens/vault/TorqueVaultV1.sol";

contract VaultTest is StrategyBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    TorqueVaultV1 private vault;
    BeefyLPStrategy private strategy;
    address private empty;

    uint256 private fosPercent;
    uint256 private fosDenominator;

    function setUp() public override {
        super.setUp();

        strategy = _getStrategy();
        empty = _getEmpty();

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), strategy, _getEmpty(), 1, 1000);

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        fosPercent = Config.getFosPercent();
        fosDenominator = Config.getFosDenominator();

        address[] memory spender = new address[](1);
        spender[0] = address(vault);
        _approveAll(spender);
    }

    // Test a deposit and redeem with the vault and Beefy LP strategy.
    function testDepositRedeem() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds into the vault
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        vault.deposit(tokenAmount);

        // Check the balances of the vault and the user
        for (uint256 i = 0; i < token.length; i++) {
            assertEq(initialBalance[i].sub(token[i].balanceOf(address(this))), tokenAmount[i]);

            AssertUtils.assertApproxEqual(vault.approxBalance(token[i]), tokenAmount[i], fosPercent, fosDenominator);
        }

        // Attempt to withdraw
    }

    // Inject and eject vault funds into the strategy.
    function testInjectEjectAll() public useFunds {}
}
