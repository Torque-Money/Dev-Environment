//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {BaseStrategy} from "./BaseStrategy.sol";

import {Vault} from "../../../../../src/lens/vault/Vault.sol";

contract VaultTest is BaseStrategy {
    using SafeMathUpgradeable for uint256;

    Vault private vault;

    function setUp() public override {
        super.setUp();

        vault = new Vault();
        vault.initialize(_token, _strategy, _empty, 0, 1);

        _strategy.grantRole(_strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        address[] memory spender = new address[](1);
        spender[0] = address(vault);
        _approveAll(spender);
    }

    // Test a deposit and redeem with the vault and Beefy LP strategy.
    function testDepositRedeem() public useFunds(vm) {
        // Deposit funds into the vault
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        uint256 shares = vault.deposit(_tokenAmount);

        // Check the balances of the vault and the user
        for (uint256 i = 0; i < _token.length; i++) {
            assertEq(initialBalance[i].sub(_token[i].balanceOf(address(this))), _tokenAmount[i]);

            _assertApproxEq(vault.approxBalance(_token[i]), _tokenAmount[i]);
        }

        // Withdraw funds and check the balances
        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < _token.length; i++) {
            _assertApproxEq(_token[i].balanceOf(address(this)), initialBalance[i]);
            _assertApproxEq(out[i], _tokenAmount[i]);

            // _assertApproxEq(vault.approxBalance(_token[i]), 0);
        }
    }

    // Test the flow of funds between the vault and the strategy
    function testFundFlow() public useFunds(vm) {
        // Deposit funds
        uint256 shares = vault.deposit(_tokenAmount);

        // Check that vault has been allocated the correct amount of tokens and they have flowed into the right contracts
        for (uint256 i = 0; i < _token.length; i++) {
            _assertApproxEq(vault.approxBalance(_token[i]), _tokenAmount[i]);
            _assertApproxEq(_token[i].balanceOf(address(vault)), 0);

            _assertApproxEq(_strategy.approxBalance(_token[i]), _tokenAmount[i]);
        }

        vault.redeem(shares);
    }
}
