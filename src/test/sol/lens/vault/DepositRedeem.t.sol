//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {VaultBase} from "./VaultBase.sol";

import {Config} from "../../helpers/Config.sol";
import {Empty} from "../../helpers/Empty.sol";
import {MockStrategy} from "../../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract VaultTest is VaultBase {
    using SafeMath for uint256;

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
        uint256 expectedShares = vault.previewDeposit(tokenAmount);
        vault.deposit(tokenAmount);

        assertEq(expectedShares, 0);
        assertEq(vault.balanceOf(address(this)), 0);

        // Check that the vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) assertEq(vault.balance(token[i]), tokenAmount[i]);

        // Redeposit to accumulate the lost funds
        tokenAmount = Config.getTokenAmount();

        uint256[] memory initialAmount = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) initialAmount[i] = token[i].balanceOf(address(this));

        vault.redeem(vault.deposit(tokenAmount));

        // Check that the amount allocated out was more than the initial deposit
        // for (uint256 i = 0; i < token.length; i++) assertGt(token[i].balanceOf(address(this)).sub(initialAmount[i]), tokenAmount[i]); // **** Isnt going to be the case for the first one that we deposited 0 into
    }

    // function testDepositRedeemWithFundInjection() public {}

    // function testDepositRedeemMultiple() public {}
}
