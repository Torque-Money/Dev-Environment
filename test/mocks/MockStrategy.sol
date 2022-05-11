//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {IStrategy} from "../../src/interfaces/lens/IStrategy.sol";
import {ISupportsToken} from "../../src/interfaces/utils/ISupportsToken.sol";
import {SupportsTokenUpgradeable} from "../../src/utils/SupportsTokenUpgradeable.sol";
import {EmergencyUpgradeable} from "../../src/utils/EmergencyUpgradeable.sol";

// This strategy will take two tokens and will deposit them into the correct LP pair for the given pool.
// It will then take the LP token and deposit it into a Beefy vault.

contract MockStrategy is Initializable, AccessControlUpgradeable, IStrategy, SupportsTokenUpgradeable, EmergencyUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public STRATEGY_ADMIN_ROLE;
    bytes32 public STRATEGY_CONTROLLER_ROLE;

    constructor(IERC20Upgradeable[] memory token) {
        _initialize(token);
    }

    function _initialize(IERC20Upgradeable[] memory token) internal initializer {
        require(token.length == 2, "MockStrategy: Strategy supports exactly 2 tokens");

        __AccessControl_init();
        __SupportsToken_init(token);
        __Emergency_init();

        STRATEGY_ADMIN_ROLE = keccak256("STRATEGY_ADMIN_ROLE");
        _setRoleAdmin(STRATEGY_ADMIN_ROLE, STRATEGY_ADMIN_ROLE);
        _grantRole(STRATEGY_ADMIN_ROLE, _msgSender());

        STRATEGY_CONTROLLER_ROLE = keccak256("STRATEGY_CONTROLLER_ROLE");
        _setRoleAdmin(STRATEGY_CONTROLLER_ROLE, STRATEGY_ADMIN_ROLE);
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

    function _withdraw(uint256[] memory amount) private returns (uint256[] memory actual) {
        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransfer(_msgSender(), amount[i]);
        return amount;
    }

    function withdraw(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) returns (uint256[] memory actual) {
        return _withdraw(amount);
    }

    function withdrawAll() external onlyRole(STRATEGY_CONTROLLER_ROLE) returns (uint256[] memory actual) {
        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++) amount[i] = tokenByIndex(i).balanceOf(address(this));

        return _withdraw(amount);
    }

    function approxBalance(IERC20Upgradeable token) public view override(ISupportsToken, SupportsTokenUpgradeable) onlySupportedToken(token) returns (uint256 amount) {
        return token.balanceOf(address(this));
    }
}
