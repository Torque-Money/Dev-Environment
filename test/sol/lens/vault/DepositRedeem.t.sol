//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {BaseVault} from "./BaseVault.sol";

import "forge-std/console2.sol";

contract DepositRedeemTest is BaseVault {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Test a regular deposit and redeem.
    function testDepositRedeem() public useFunds(vm) {
        // Check that the estimated shares matches the allocated shares
        uint256 expectedShares = _vault.estimateDeposit(_tokenAmount);
        uint256 shares = _vault.deposit(_tokenAmount);

        _assertApproxEq(expectedShares, shares);
        assertEq(_vault.balanceOf(address(this)), shares);

        // Check that the recipient has shares minted
        assertGt(_vault.balanceOf(_vault.feeRecipient()), 0);

        // Check that vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(_vault.approxBalance(_token[i]), _tokenAmount[i]);

        // Check that the redeem estimate matches the amount allocated and check that the amount out is less than what was deposited
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        uint256[] memory expectedOut = _vault.estimateRedeem(shares);
        uint256[] memory out = _vault.redeem(shares);

        for (uint256 i = 0; i < _token.length; i++) {
            assertEq(_token[i].balanceOf(address(this)).sub(initialBalance[i]), out[i]);

            _assertApproxEq(expectedOut[i], out[i]);
            assertLt(out[i], _tokenAmount[i]);
        }

        // Check the the correct shares are burned
        assertEq(_vault.balanceOf(address(this)), 0);
    }

    // Test a deposit and redeem when one of the amounts deposited is zero.
    function testDepositRedeemZero() public useFunds(vm) {
        // Check that the shares becomes zero
        uint256[] memory tmpTokenAmount = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) tmpTokenAmount[i] = _tokenAmount[i];
        tmpTokenAmount[0] = 0;

        uint256 shares = _vault.deposit(tmpTokenAmount);

        assertEq(shares, 0);

        // Check that the vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(_vault.approxBalance(_token[i]), tmpTokenAmount[i]);

        // Check that a new depositor receives the allocated funds that were locked in the pool by the initial zero deposit
        uint256[] memory out = _vault.redeem(_vault.deposit(_tokenAmount));

        console2.log("Out");
        console2.log(out[0]);
        console2.log(out[1]);

        assertGt(out[1], _tokenAmount[1]);
    }

    // Test a deposit and redeem when funds have been injected to the vault after the deposit.
    function testDepositRedeemWithTokenInjection() public useFunds(vm) {
        // Deposit funds initially
        uint256 shares = _vault.deposit(_tokenAmount);

        // Compare the allocated assets before and after the token injection
        uint256[] memory initialOut = _vault.estimateRedeem(shares);

        for (uint256 i = 0; i < _token.length; i++) _token[i].safeTransfer(address(_vault), _tokenAmount[i]);

        uint256[] memory out = _vault.redeem(shares);

        for (uint256 i = 0; i < _token.length; i++) assertGt(out[i], initialOut[i]);
    }

    // Test a deposit and redeem when multiple users have deposited into the vault.
    function testDepositRedeemMultiple() public useFunds(vm) {
        // Deposit initial funds from account 0
        uint256 shares0 = _vault.deposit(_tokenAmount);
        uint256[] memory out0 = _vault.estimateRedeem(shares0);

        // Transfer funds to account 2
        for (uint256 i = 0; i < _token.length; i++) _token[i].safeTransfer(_empty, _tokenAmount[i]);

        // Make deposit on behalf of account 2
        vm.startPrank(_empty);
        {
            address[] memory spender = new address[](1);
            spender[0] = address(_vault);
            _approveAll(spender);

            uint256 shares1 = _vault.deposit(_tokenAmount);
            uint256[] memory out1 = _vault.estimateRedeem(shares1);

            for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(out0[i], out1[i]);

            _vault.redeem(shares1);
        }
        vm.stopPrank();

        _vault.redeem(shares0);
    }

    // Test a deposit and redeem when multiple users have deposited into the vault and a fund injection has been made.
    function testDepositRedeemMultipleWithInjection() public useFunds(vm) {
        // Use 0 fees for the test
        (uint256 percent, uint256 denominator) = _vault.feePercent();
        _vault.setFeePercent(0, denominator);

        // Deposit initial funds from account 0 and inject funds
        uint256 shares0 = _vault.deposit(_tokenAmount);
        for (uint256 i = 0; i < _token.length; i++) _token[i].safeTransfer(_empty, _tokenAmount[i]);
        uint256[] memory out0 = _vault.estimateRedeem(shares0);

        // Make deposit on behalf of account 2
        vm.startPrank(_empty);
        {
            address[] memory spender = new address[](1);
            spender[0] = address(_vault);
            _approveAll(spender);

            // Check that after a deposit the initial user still has the same output shares (approximately)
            uint256 shares1 = _vault.deposit(_tokenAmount);

            uint256[] memory out0New = _vault.estimateRedeem(shares0);
            for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(out0[i], out0New[i]);

            // Check that redeeming ends with the same tokens as initially deposited for the second user
            uint256[] memory out1 = _vault.redeem(shares1);

            for (uint256 i = 0; i < _token.length; i++) _assertApproxEq(_tokenAmount[i], out1[i]);
        }
        vm.stopPrank();

        _vault.redeem(shares0);

        // Reset the fees
        _vault.setFeePercent(percent, denominator);
    }
}
