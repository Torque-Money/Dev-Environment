//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {IVaultV1} from "../../interfaces/lens/IVaultV1.sol";
import {IStrategy} from "../../interfaces/lens/IStrategy.sol";
import {ISupportsToken} from "../../interfaces/utils/ISupportsToken.sol";
import {SupportsToken} from "../../utils/SupportsToken.sol";
import {SupportsFee} from "../../utils/SupportsFee.sol";
import {Emergency} from "../../utils/Emergency.sol";

contract TorqueVaultV1 is Initializable, AccessControlUpgradeable, ERC20Upgradeable, SupportsToken, IVaultV1, SupportsFee, Emergency {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public VAULT_ADMIN_ROLE;
    bytes32 public VAULT_CONTROLLER_ROLE;

    IStrategy private strategy;

    function initialize(
        IERC20Upgradeable[] memory token,
        IStrategy _strategy,
        address _feeRecipient,
        uint256 _feePercent,
        uint256 _feePercentDenominator
    ) external initializer {
        __ERC20_init("Torque Vault V1", "TVV1");
        __AccessControl_init();
        __SupportsToken_init(token);
        __SupportsFee_init(_feeRecipient, _feePercent, _feePercentDenominator, 0);
        __Emergency_init();

        VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");
        _setRoleAdmin(VAULT_ADMIN_ROLE, VAULT_ADMIN_ROLE);
        _grantRole(VAULT_ADMIN_ROLE, _msgSender());

        VAULT_CONTROLLER_ROLE = keccak256("VAULT_CONTROLLER_ROLE");
        _setRoleAdmin(VAULT_CONTROLLER_ROLE, VAULT_ADMIN_ROLE);

        strategy = _strategy;
    }

    function setStrategy(IStrategy _strategy) external override onlyRole(VAULT_CONTROLLER_ROLE) {
        strategy = _strategy;
    }

    function getStrategy() external view override returns (IStrategy _strategy) {
        return strategy;
    }

    function _sharesFromAmount(
        IERC20Upgradeable token,
        uint256 amount,
        uint256 totalShares
    ) private view returns (uint256 shares) {
        uint256 _balance = approxBalance(token);

        if (_balance == 0) shares = amount;
        else shares = amount.mul(totalShares).div(_balance);
    }

    function _estimateDeposit(uint256[] memory amount) private view returns (uint256 shares, uint256 fees) {
        uint256 _totalShares = totalSupply();

        if (_totalShares == 0) {
            shares = amount[0];

            for (uint256 i = 1; i < tokenCount(); i++) {
                uint256 _amount = amount[i];
                if (_amount < shares) shares = _amount;
            }
        } else {
            shares = _sharesFromAmount(tokenByIndex(0), amount[0], _totalShares);

            for (uint256 i = 1; i < tokenCount(); i++) {
                uint256 _shares = _sharesFromAmount(tokenByIndex(i), amount[i], _totalShares);
                if (_shares < shares) shares = _shares;
            }
        }

        (uint256 percent, uint256 denominator) = feePercent();
        fees = shares.mul(percent).div(denominator);
        shares = shares.sub(fees);
    }

    function estimateDeposit(uint256[] memory amount) public view override onlyTokenAmount(amount) returns (uint256 shares) {
        (shares, ) = _estimateDeposit(amount);
    }

    function deposit(uint256[] memory amount) external override onlyTokenAmount(amount) returns (uint256 shares) {
        uint256 fees;
        (shares, fees) = _estimateDeposit(amount);

        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransferFrom(_msgSender(), address(this), amount[i]);

        _depositAllIntoStrategy();

        _mint(_msgSender(), shares);
        _mint(feeRecipient(), fees);

        emit Deposit(_msgSender(), amount, shares);
    }

    function estimateRedeem(uint256 shares) public view override returns (uint256[] memory amount) {
        uint256 _totalShares = totalSupply();

        amount = new uint256[](tokenCount());
        if (_totalShares == 0) return amount;

        for (uint256 i = 0; i < tokenCount(); i++) {
            IERC20Upgradeable token = tokenByIndex(i);

            uint256 _balance = approxBalance(token);
            amount[i] = _balance.mul(shares).div(_totalShares);
        }
    }

    function redeem(uint256 shares) external override returns (uint256[] memory amount) {
        amount = estimateRedeem(shares);

        _withdrawAllFromStrategy();

        for (uint256 i = 0; i < tokenCount(); i++) {
            IERC20Upgradeable token = tokenByIndex(i);

            amount[i] = MathUpgradeable.min(amount[i], token.balanceOf(address(this)));
            token.safeTransfer(_msgSender(), amount[i]);
        }

        _depositAllIntoStrategy();

        _burn(_msgSender(), shares);

        emit Redeem(_msgSender(), shares, amount);
    }

    function approxBalance(IERC20Upgradeable token) public view override(ISupportsToken, SupportsToken) onlySupportedToken(token) returns (uint256 amount) {
        return token.balanceOf(address(this)).add(strategy.approxBalance(token));
    }

    function _depositIntoStrategy(uint256[] memory amount) private {
        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeIncreaseAllowance(address(strategy), amount[i]);

        strategy.deposit(amount);
    }

    function _depositAllIntoStrategy() private {
        for (uint256 i = 0; i < tokenCount(); i++) {
            IERC20Upgradeable token = tokenByIndex(i);
            token.safeIncreaseAllowance(address(strategy), token.balanceOf(address(this)));
        }

        strategy.depositAll();
    }

    function _withdrawFromStrategy(uint256[] memory amount) private {
        strategy.withdraw(amount);
    }

    function _withdrawAllFromStrategy() private {
        strategy.withdrawAll();
    }

    function depositIntoStrategy(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(VAULT_CONTROLLER_ROLE) {
        _depositIntoStrategy(amount);
    }

    function depositAllIntoStrategy() external onlyRole(VAULT_CONTROLLER_ROLE) {
        _depositAllIntoStrategy();
    }

    function withdrawFromStrategy(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(VAULT_CONTROLLER_ROLE) {
        _withdrawFromStrategy(amount);
    }

    function withdrawAllFromStrategy() external onlyRole(VAULT_CONTROLLER_ROLE) {
        _withdrawAllFromStrategy();
    }
}
