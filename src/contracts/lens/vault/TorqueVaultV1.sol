//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IVaultV1} from "../../interfaces/lens/vault/IVaultV1.sol";
import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {Emergency} from "../../utils/Emergency.sol";
import {SupportsToken} from "../../utils/SupportsToken.sol";

contract TorqueVaultV1 is
    Initializable,
    AccessControlUpgradeable,
    IVaultV1,
    ERC20Upgradeable,
    SupportsToken,
    Emergency
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public VAULT_ADMIN_ROLE;
    bytes32 public VAULT_CONTROLLER_ROLE;

    IStrategy public strategy;

    function initialize(IERC20[] memory token) external initializer {
        __ERC20_init("Torque Vault V1", "TVV1");
        __AccessControl_init();
        __SupportsToken_init(token);

        VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");
        _setRoleAdmin(VAULT_ADMIN_ROLE, VAULT_ADMIN_ROLE);
        _grantRole(VAULT_ADMIN_ROLE, _msgSender());

        VAULT_CONTROLLER_ROLE = keccak256("VAULT_CONTROLLER_ROLE");
        _setRoleAdmin(VAULT_CONTROLLER_ROLE, VAULT_ADMIN_ROLE);
        _grantRole(VAULT_CONTROLLER_ROLE, address(this));
    }

    function setStrategy(IStrategy _strategy)
        external
        override
        onlyRole(VAULT_CONTROLLER_ROLE)
    {
        strategy = _strategy;
    }

    function _sharesFromAmount(
        IERC20 token,
        uint256 amount,
        uint256 totalShares
    ) private view returns (uint256 shares) {
        // Helper for calculating the shares owed for a
        // given deposited amount of assets at the correct ratio

        uint256 _balance = balance(token);

        if (_balance == 0) shares = amount;
        else shares = amount.mul(totalShares).div(_balance);
    }

    function previewDeposit(uint256[] calldata amount)
        public
        view
        override
        returns (uint256 shares)
    {
        // Get the minimum amount of shares
        // across all deposited amounts

        uint256 _totalShares = totalSupply();

        if (_totalShares == 0) {
            // If there are no shares minted yet, choose the smallest
            // deposit amount as the initial share count

            shares = amount[0];

            for (uint256 i = 1; i < tokenCount(); i++) {
                uint256 _amount = amount[i];
                if (_amount < shares) shares = _amount;
            }
        } else {
            shares = _sharesFromAmount(
                tokenByIndex(0),
                amount[0],
                _totalShares
            );

            for (uint256 i = 1; i < tokenCount(); i++) {
                uint256 _shares = _sharesFromAmount(
                    tokenByIndex(i),
                    amount[i],
                    _totalShares
                );
                if (_shares < shares) shares = _shares;
            }
        }
    }

    function deposit(uint256[] calldata amount)
        external
        override
        returns (uint256 shares)
    {
        // Get the owed shares, transfer funds to the vault,
        // deposit funds into the strategy, and mint the owed shares

        shares = previewDeposit(amount);

        for (uint256 i = 0; i < tokenCount(); i++)
            tokenByIndex(i).safeTransferFrom(
                _msgSender(),
                address(this),
                amount[i]
            );
        depositAllIntoStrategy();

        _mint(_msgSender(), shares);

        emit Deposit(_msgSender(), amount, shares);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256[] memory amount)
    {
        // Calculate the percentage of each asset the shares account for
        uint256 _totalShares = totalSupply();

        amount = new uint256[](tokenCount());
        if (_totalShares == 0) return amount; // Initialized with zeroes

        for (uint256 i = 0; i < tokenCount(); i++) {
            uint256 _balance = balance(tokenByIndex(i));
            amount[i] = _balance.mul(shares).div(_totalShares);
        }
    }

    function redeem(uint256 shares)
        external
        override
        returns (uint256[] memory amount)
    {
        // Calculate the owed assets, withdraw from the strategy,
        // transfer assets to the caller, deposit assets back into the strategy,
        // burn shares

        amount = previewRedeem(shares);

        withdrawAllFromStrategy();
        for (uint256 i = 0; i < tokenCount(); i++)
            tokenByIndex(i).safeTransfer(_msgSender(), amount[i]);
        depositAllIntoStrategy();

        _burn(_msgSender(), shares);

        emit Redeem(_msgSender(), shares, amount);
    }

    function balance(IERC20 token)
        public
        view
        override
        returns (uint256 amount)
    {
        return token.balanceOf(address(this)).add(strategy.balance(token));
    }

    function depositAllIntoStrategy()
        public
        override
        onlyRole(VAULT_CONTROLLER_ROLE)
    {
        // Approve the strategy to use all vault assets
        // and then deposit the full amounts into the strategy

        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++) {
            IERC20 token = tokenByIndex(i);
            amount[i] = token.balanceOf(address(this));
            token.safeApprove(address(strategy), amount[i]);
        }

        strategy.deposit(amount);
    }

    function withdrawAllFromStrategy()
        public
        override
        onlyRole(VAULT_CONTROLLER_ROLE)
    {
        // Get the balance of each vault asset in the
        // strategy and withdraw them into the vault

        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++)
            amount[i] = strategy.balance(tokenByIndex(i));

        strategy.withdraw(amount);
    }

    function inCaseTokensGetStuck(IERC20 token, uint256 amount)
        public
        override
        onlyRole(VAULT_ADMIN_ROLE)
    {
        super.inCaseTokensGetStuck(token, amount);
    }
}
