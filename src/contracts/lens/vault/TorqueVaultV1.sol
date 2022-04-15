//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IVaultV1} from "../../interfaces/lens/vault/IVaultV1.sol";
import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {Emergency} from "../../utils/Emergency.sol";

import {FractionMath} from "../../lib/FractionMath.sol";

contract TorqueVaultV1 is
    Initializable,
    AccessControlEnumerableUpgradeable,
    IVaultV1,
    ERC20Upgradeable,
    Emergency
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using FractionMath for FractionMath.Fraction;

    bytes32 public VAULT_ADMIN_ROLE;
    bytes32 public VAULT_CONTROLLER_ROLE;

    IStrategy public strategy;
    EnumerableSet.AddressSet private tokenSet;

    function initialize(IERC20[] memory token) external initializer {
        __ERC20_init("Torque Vault V1", "TVV1");
        __AccessControlEnumerable_init();

        VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");
        _setRoleAdmin(VAULT_ADMIN_ROLE, VAULT_ADMIN_ROLE);
        _grantRole(VAULT_ADMIN_ROLE, _msgSender());

        VAULT_CONTROLLER_ROLE = keccak256("VAULT_CONTROLLER_ROLE");
        _setRoleAdmin(VAULT_CONTROLLER_ROLE, VAULT_ADMIN_ROLE);
        _grantRole(VAULT_CONTROLLER_ROLE, address(this));

        require(
            token.length > 0,
            "TorqueVaultV1: Vault requires at least 1 token"
        );
        for (uint256 i = 0; i < token.length; i++)
            tokenSet.add(address(token[i]));
    }

    function setStrategy(IStrategy _strategy)
        external
        override
        onlyRole(VAULT_CONTROLLER_ROLE)
    {
        strategy = _strategy;
    }

    function tokenCount() public view override returns (uint256 count) {
        return tokenSet.length();
    }

    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (IERC20 token)
    {
        return IERC20(tokenSet.at(index));
    }

    function previewDeposit(uint256[] calldata amount)
        external
        view
        override
        returns (uint256 shares)
    {
        uint256 _totalShares = totalSupply();
        if (_totalShares == 0) {
            shares = balance(tokenByIndex(0));

            for (uint256 i = 1; i < tokenCount(); i++) {
                uint256 _amount = balance(tokenByIndex(i));
                if (_amount < shares) shares = _amount;
            }
        } else {}

        // // **** This does not really consider the cases where the demoniator is 0... - what will we do in this case ?
        // FractionMath.Fraction memory minDeposit = FractionMath.create(
        //     amount[0],
        //     balance(tokenByIndex(0))
        // );
        // for (uint256 i = 1; i < tokenCount(); i++) {
        //     FractionMath.Fraction memory _deposit = FractionMath.create(
        //         amount[i],
        //         balance(tokenByIndex(i))
        //     );
        //     if (_deposit.lt(minDeposit)) minDeposit = _deposit;
        // }
    }

    function deposit(uint256[] calldata amount)
        external
        override
        returns (uint256 shares)
    {}

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256[] memory amount)
    {
        uint256 _totalShares = totalSupply();
        uint256[] memory _balance = new uint256[](tokenCount());

        amount = new uint256[](tokenCount());
        if (_totalShares == 0) return amount;

        for (uint256 i = 0; i < tokenCount(); i++) {
            uint256 _bal = balance(tokenByIndex(i));
            amount[i] = _bal.mul(shares).div(_totalShares);
        }
    }

    function redeem(uint256 shares)
        external
        override
        returns (uint256[] memory amount)
    {
        amount = previewRedeem(shares);

        withdrawAllFromStrategy();
        for (uint256 i = 0; i < amount.length; i++)
            tokenByIndex(i).safeTransfer(_msgSender(), amount[i]);
        depositAllIntoStrategy();

        _burn(_msgSender(), shares);

        emit Redeem(_msgSender(), shares, amount);
    }

    function balance(IERC20 token) public override returns (uint256 amount) {
        return token.balanceOf(address(this)).add(strategy.balance(token));
    }

    function depositAllIntoStrategy()
        public
        override
        onlyRole(VAULT_CONTROLLER_ROLE)
    {
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
