//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {VaultBase} from "./VaultBase.sol";

import {Config} from "../../helpers/Config.sol";

contract DepositRedeemTest is VaultBase {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Test a regular deposit and redeem.
    function testDepositRedeem() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the estimated shares matches the allocated shares
        uint256 expectedShares = vault.estimateDeposit(tokenAmount);
        uint256 shares = vault.deposit(tokenAmount);

        _assertApproxEq(expectedShares, shares);
        assertEq(vault.balanceOf(address(this)), shares);

        // Check that the recipient has shares minted
        assertGt(vault.balanceOf(vault.feeRecipient()), 0);

        // Check that vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) _assertApproxEq(vault.approxBalance(token[i]), tokenAmount[i]);

        // Check that the redeem estimate matches the amount allocated and check that the amount out is less than what was deposited
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        uint256[] memory expectedOut = vault.estimateRedeem(shares);
        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) {
            assertEq(token[i].balanceOf(address(this)).sub(initialBalance[i]), out[i]);

            _assertApproxEq(expectedOut[i], out[i]);
            assertLt(out[i], tokenAmount[i]);
        }

        // Check the the correct shares are burned
        assertEq(vault.balanceOf(address(this)), 0);
    }

    // Test a deposit and redeem when one of the amounts deposited is zero.
    function testDepositRedeemZero() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the shares becomes zero
        tokenAmount[0] = 0;
        uint256 shares = vault.deposit(tokenAmount);

        assertEq(shares, 0);

        // Check that the vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) _assertApproxEq(vault.approxBalance(token[i]), tokenAmount[i]);

        // Check that the amount allocated out was more than the initial deposit after a proper share allocation
        tokenAmount = Config.getTokenAmount();

        uint256[] memory out = vault.redeem(vault.deposit(tokenAmount));

        assertGt(out[1], tokenAmount[1]);
    }

    // Test a deposit and redeem when funds have been injected to the vault after the deposit.
    function testDepositRedeemWithTokenInjection() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds initially
        uint256 shares = vault.deposit(tokenAmount);

        // Compare the allocated assets before and after the token injection
        uint256[] memory initialOut = vault.estimateRedeem(shares);

        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(address(vault), tokenAmount[i]);

        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) assertGt(out[i], initialOut[i]);
    }

    // Test a deposit and redeem when multiple users have deposited into the vault.
    function testDepositRedeemMultiple() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit initial funds from account 0
        uint256 shares0 = vault.deposit(tokenAmount);
        uint256[] memory out0 = vault.estimateRedeem(shares0);

        // Transfer funds to account 2
        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(empty, tokenAmount[i]);

        // Make deposit on behalf of account 2
        cheats.startPrank(empty);
        {
            address[] memory spender = new address[](1);
            spender[0] = address(vault);
            _approveAll(spender);

            uint256 shares1 = vault.deposit(tokenAmount);
            uint256[] memory out1 = vault.estimateRedeem(shares1);

            for (uint256 i = 0; i < token.length; i++) _assertApproxEq(out0[i], out1[i]);

            vault.redeem(shares1);
        }
        cheats.stopPrank();

        vault.redeem(shares0);
    }

    // Test a deposit and redeem when multiple users have deposited into the vault and a fund injection has been made.
    function testDepositRedeemMultipleWithInjection() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Use 0 fees for the test
        (uint256 percent, uint256 denominator) = vault.feePercent();
        vault.setFeePercent(0, denominator);

        // Deposit initial funds from account 0 and inject funds
        uint256 shares0 = vault.deposit(tokenAmount);
        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(empty, tokenAmount[i]);
        uint256[] memory out0 = vault.estimateRedeem(shares0);

        // Make deposit on behalf of account 2
        cheats.startPrank(empty);
        {
            address[] memory spender = new address[](1);
            spender[0] = address(vault);
            _approveAll(spender);

            // Check that after a deposit the initial user still has the same output shares (approximately)
            uint256 shares1 = vault.deposit(tokenAmount);

            uint256[] memory out0New = vault.estimateRedeem(shares0);
            for (uint256 i = 0; i < token.length; i++) _assertApproxEq(out0[i], out0New[i]);

            // Check that redeeming ends with the same tokens as initially deposited for the second user
            uint256[] memory out1 = vault.redeem(shares1);

            for (uint256 i = 0; i < token.length; i++) _assertApproxEq(tokenAmount[i], out1[i]);
        }
        cheats.stopPrank();

        vault.redeem(shares0);

        // Reset the fees
        vault.setFeePercent(percent, denominator);
    }
}
