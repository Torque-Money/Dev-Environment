//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

// Provides an interface for a contract to support Torque vault V1 core
interface ITorqueVaultV1Core is IERC20Upgradeable {
    // Returns the number of tokens the vault supports
    function tokenCount() external view returns (uint256 _tokenCount);

    // Gets a token supported by the vault by its index. Must be less than token count or else will revert
    function getTokenByIndex(uint256 index) external view returns (address token);

    // Previews the amount of shares for depositing a given amount of tokens into the vault from the sender.
    function previewDeposit(uint256[] calldata amount) external view returns (uint256 shares);

    // Deposit vault supported tokens from the sender into the vault for shares.
    // It is important that the tokens supported match the correct ratios or else additional funds deposited will be lost.
    // Reverts if funds are not available.
    function deposit(uint256[] calldata amount) external returns (uint256 shares);

    // Previews the amount of tokens for redeeming a given amount of shares
    function previewRedeem(uint256 shares) external view returns (uint256[] calldata amount);

    // Redeem shares from the sender for an underlying amount of tokens
    function redeem(uint256 shares) external returns (uint256[] calldata amount);
}
