//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {VaultBase} from "./VaultBase.sol";

import {Config} from "../../helpers/Config.sol";
import {Empty} from "../../helpers/Empty.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract VaultTest is VaultBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function testDepositRedeem() public {
        TorqueVaultV1 vault = _getVault();

        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the previewed shares matches the allocated shares
        uint256 expectedShares = vault.previewDeposit(tokenAmount);
        vault.deposit(tokenAmount);

        assertEq(vault.balanceOf(address(this)), expectedShares);

        // Check that the recipient has shares minted
        assertGt(vault.balanceOf(vault.feeRecipient()), 0);

        // Check that vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) assertEq(vault.balance(token[i]), tokenAmount[i]);

        // Check that the redeem preview matches the amount allocated and check that the amount out is less than what was deposited
        uint256[] memory expectedOut = vault.previewRedeem(expectedShares);

        uint256[] memory initialAmount = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialAmount[i] = token[i].balanceOf(address(this));

        vault.redeem(expectedShares);

        for (uint256 i = 0; i < token.length; i++) {
            uint256 out = token[i].balanceOf(address(this)).sub(initialAmount[i]);
            assertEq(expectedOut[i], out);
            assertLt(out, tokenAmount[i]);
        }

        // Check the the correct shares are burned
        assertEq(vault.balanceOf(address(this)), 0);
    }

    function testDepositRedeemZero() public {
        TorqueVaultV1 vault = _getVault();

        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the previewed shares becomes zero
        tokenAmount[0] = 0;
        uint256 shares = vault.deposit(tokenAmount);

        assertEq(shares, 0);
        assertEq(vault.balanceOf(address(this)), 0);

        // Check that the vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) assertEq(vault.balance(token[i]), tokenAmount[i]);

        // Check that the amount allocated out was more than the initial deposit after a proper share allocation
        tokenAmount = Config.getTokenAmount();

        uint256[] memory out = vault.redeem(vault.deposit(tokenAmount));

        assertGt(out[1], tokenAmount[1]);
    }

    function testDepositRedeemWithTokenInjection() public {
        TorqueVaultV1 vault = _getVault();

        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit funds initially
        uint256 shares = vault.deposit(tokenAmount);

        // Compare the allocated assets before and after the token injection
        uint256[] memory initialOut = vault.previewRedeem(shares);

        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(address(vault), tokenAmount[i]);

        uint256[] memory out = vault.redeem(shares);

        for (uint256 i = 0; i < token.length; i++) assertGt(out[i], initialOut[i]);
    }

    function testDepositRedeemMultiple() public {
        TorqueVaultV1 vault = _getVault();
        Empty empty = _getEmpty();

        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit initial funds from account 0
        uint256 shares0 = vault.deposit(tokenAmount);
        uint256[] memory out0 = vault.previewRedeem(shares0);

        ICheatCodes cheats = Config.getCheatCodes();

        // Transfer funds to account 2
        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(address(empty), tokenAmount[i]);

        // Make deposit on behalf of account 2
        cheats.startPrank(address(empty));
        {
            address[] memory spender = new address[](1);
            spender[0] = address(vault);
            _approveAll(spender);

            uint256 shares1 = vault.deposit(tokenAmount);
            uint256[] memory out1 = vault.redeem(shares1);

            for (uint256 i = 0; i < token.length; i++) assertEq(out0[i], out1[i]);
        }
        cheats.stopPrank();

        vault.redeem(shares0);
    }

    function testDepositRedeemMultipleWithInjection() public {
        // **** I want to test this by

        TorqueVaultV1 vault = _getVault();
        Empty empty = _getEmpty();

        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Deposit initial funds from account 0
        uint256 shares0 = vault.deposit(tokenAmount);
        uint256[] memory out0 = vault.previewRedeem(shares0);

        ICheatCodes cheats = Config.getCheatCodes();

        // Transfer funds to account 2
        for (uint256 i = 0; i < token.length; i++) token[i].safeTransfer(address(empty), tokenAmount[i]);

        // Make deposit on behalf of account 2
        cheats.startPrank(address(empty));
        {
            address[] memory spender = new address[](1);
            spender[0] = address(vault);
            _approveAll(spender);

            uint256 shares1 = vault.deposit(tokenAmount);
            uint256[] memory out1 = vault.redeem(shares1);

            for (uint256 i = 0; i < token.length; i++) assertEq(out0[i], out1[i]);
        }
        cheats.stopPrank();

        vault.redeem(shares0);
    }
}
