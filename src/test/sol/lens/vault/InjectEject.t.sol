//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {VaultBase} from "./VaultBase.sol";

import {Config} from "../../helpers/Config.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract InjectEjectTest is VaultBase {
    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() public override {
        super.setUp();

        vault = _getVault();
        strategy = _getStrategy();
    }

    // Inject and eject vault funds into the strategy.
    function testDepositAllIntoStrategy() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Make deposit and check the balance is updated correctly
        uint256 shares = vault.deposit(tokenAmount);

        // Check that vault has been allocated the correct amount of tokens and they have flowed into the right contracts
        for (uint256 i = 0; i < token.length; i++) {
            assertEq(vault.approxBalance(token[i]), tokenAmount[i]);
            assertEq(token[i].balanceOf(address(vault)), 0);

            assertEq(strategy.approxBalance(token[i]), tokenAmount[i]);
            assertEq(token[i].balanceOf(address(strategy)), tokenAmount[i]);
        }

        // Withdraw shares and check funds have flowed correctly
        vault.withdrawAllFromStrategy();

        for (uint256 i = 0; i < token.length; i++) {
            assertEq(vault.approxBalance(token[i]), tokenAmount[i]);
            assertEq(token[i].balanceOf(address(vault)), tokenAmount[i]);

            assertEq(strategy.approxBalance(token[i]), 0);
            assertEq(token[i].balanceOf(address(strategy)), 0);
        }

        vault.redeem(shares);
    }
}
