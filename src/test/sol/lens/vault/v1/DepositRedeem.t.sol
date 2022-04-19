//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICheatCodes} from "../../../helpers/ICheatCodes.sol";

import {VaultBase} from "./VaultBase.sol";

import {Config} from "../../../helpers/Config.sol";
import {AssertUtils} from "../../../helpers/AssertUtils.sol";
import {MockStrategy} from "../../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "../../../../../contracts/lens/vault/TorqueVaultV1.sol";

contract DepositRedeemTest is VaultBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    TorqueVaultV1 private vault;
    address private empty;
    ICheatCodes private cheats;

    uint256 private fosPercent;
    uint256 private fosDenominator;

    function setUp() public override {
        super.setUp();

        vault = _getVault();
        empty = _getEmpty();
        cheats = _getCheats();

        fosPercent = Config.getFosPercent();
        fosDenominator = Config.getFosDenominator();
    }

    // Test a regular deposit and redeem.
    function testDepositRedeem() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the estimated shares matches the allocated shares
        uint256 expectedShares = vault.estimateDeposit(tokenAmount);
        uint256 shares = vault.deposit(tokenAmount);

        AssertUtils.assertApproxEqual(expectedShares, shares, fosPercent, fosDenominator);
        assertEq(vault.balanceOf(address(this)), shares);

        // Check that the recipient has shares minted
        assertGt(vault.balanceOf(vault.feeRecipient()), 0);

        // Check that vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) AssertUtils.assertApproxEqual(vault.approxBalance(token[i]), tokenAmount[i], fosPercent, fosDenominator);

        // Check that the redeem estimate matches the amount allocated and check that the amount out is less than what was deposited
        uint256[] memory initialBalance = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialBalance[i] = token[i].balanceOf(address(this));

        uint256[] memory expectedOut = vault.estimateRedeem(shares);
        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) {
            assertEq(token[i].balanceOf(address(this)).sub(initialBalance[i]), out[i]);

            AssertUtils.assertApproxEqual(expectedOut[i], out[i], fosPercent, fosDenominator);
            assertLt(out[i], tokenAmount[i]);
        }

        // Check the the correct shares are burned
        assertEq(vault.balanceOf(address(this)), 0);
    }

    // Test a deposit and redeem when one of the amounts deposited is zero.
    function testDepositRedeemZero() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the shares becomes zero
        tokenAmount[0] = 0;
        uint256 shares = vault.deposit(tokenAmount);

        assertEq(shares, 0);

        // Check that the vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) AssertUtils.assertApproxEqual(vault.approxBalance(token[i]), tokenAmount[i], fosPercent, fosDenominator);

        // Check that the amount allocated out was more than the initial deposit after a proper share allocation
        tokenAmount = Config.getTokenAmount();

        uint256[] memory out = vault.redeem(vault.deposit(tokenAmount));

        assertGt(out[1], tokenAmount[1]);
    }

    // Test a deposit and redeem when funds have been injected to the vault after the deposit.
    function testDepositRedeemWithTokenInjection() public useFunds {
        IERC20[] memory token = Config.getToken();
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
        IERC20[] memory token = Config.getToken();
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

            for (uint256 i = 0; i < token.length; i++) AssertUtils.assertApproxEqual(out0[i], out1[i], fosPercent, fosDenominator);

            vault.redeem(shares1);
        }
        cheats.stopPrank();

        vault.redeem(shares0);
    }

    // Test a deposit and redeem when multiple users have deposited into the vault and a fund injection has been made.
    function testDepositRedeemMultipleWithInjection() public useFunds {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Use 0 fees for the test
        uint256 amount = vault.feeAmount();
        vault.setFeeAmount(0);
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
            for (uint256 i = 0; i < token.length; i++) AssertUtils.assertApproxEqual(out0[i], out0New[i], fosPercent, fosDenominator);

            // Check that redeeming ends with the same tokens as initially deposited for the second user
            uint256[] memory out1 = vault.redeem(shares1);

            for (uint256 i = 0; i < token.length; i++) AssertUtils.assertApproxEqual(tokenAmount[i], out1[i], fosPercent, fosDenominator);
        }
        cheats.stopPrank();

        vault.redeem(shares0);

        // Reset the fees
        vault.setFeePercent(percent, denominator);
        vault.setFeeAmount(amount);
    }
}
