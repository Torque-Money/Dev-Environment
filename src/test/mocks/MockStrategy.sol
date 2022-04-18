//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IStrategyAPY} from "@contracts/interfaces/lens/strategy/IStrategyAPY.sol";
import {ISupportsToken} from "@contracts/interfaces/utils/ISupportsToken.sol";
import {SupportsToken} from "@contracts/utils/SupportsToken.sol";
import {Emergency} from "@contracts/utils/Emergency.sol";

// This strategy will take two tokens and will deposit them into the correct LP pair for the given pool.
// It will then take the LP token and deposit it into a Beefy vault.

contract MockStrategy is Initializable, AccessControlUpgradeable, IStrategyAPY, SupportsToken, Emergency {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public STRATEGY_ADMIN_ROLE;
    bytes32 public STRATEGY_CONTROLLER_ROLE;

    uint256 private twaAPY;

    function initialize(IERC20[] memory token, uint256 initialAPY) external initializer {
        __AccessControl_init();
        __SupportsToken_init(token, 2);
        __Emergency_init();

        STRATEGY_ADMIN_ROLE = keccak256("STRATEGY_ADMIN_ROLE");
        _setRoleAdmin(STRATEGY_ADMIN_ROLE, STRATEGY_ADMIN_ROLE);
        _grantRole(STRATEGY_ADMIN_ROLE, _msgSender());

        STRATEGY_CONTROLLER_ROLE = keccak256("STRATEGY_CONTROLLER_ROLE");
        _setRoleAdmin(STRATEGY_CONTROLLER_ROLE, STRATEGY_ADMIN_ROLE);

        twaAPY = initialAPY;
    }

    function _deposit(uint256[] memory amount) private {
        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransferFrom(_msgSender(), address(this), amount[i]);
    }

    function deposit(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) {
        _deposit(amount);
    }

    function depositAll() external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++) amount[i] = tokenByIndex(i).balanceOf(_msgSender());

        _deposit(amount);
    }

    function _withdraw(uint256[] memory amount) private {
        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransfer(_msgSender(), amount[i]);
    }

    function withdraw(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) {
        _withdraw(amount);
    }

    function withdrawAll() external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++) amount[i] = tokenByIndex(i).balanceOf(address(this));

        _withdraw(amount);
    }

    function APY() external view returns (uint256 apy, uint256 decimals) {
        return (twaAPY, 1e4);
    }

    function updateAPY(uint256 apy) external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        uint256 EMA_WEIGHT_PERCENT = 70;

        uint256 temp = twaAPY.mul(uint256(100).sub(EMA_WEIGHT_PERCENT).div(100));
        temp = temp.add(apy.mul(EMA_WEIGHT_PERCENT).div(100));

        twaAPY = temp;
    }

    function approxBalance(IERC20 token) public view override(ISupportsToken, SupportsToken) onlySupportedToken(token) returns (uint256 amount) {
        return token.balanceOf(address(this));
    }
}
