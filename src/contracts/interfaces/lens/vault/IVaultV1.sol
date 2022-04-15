//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IStrategy} from "../strategy/IStrategy.sol";

// A multi-token vault that tracks each users share with its own ERC20 interface. Manages deposited funds using a strategy to earn rewards.
interface IVaultV1 is IERC20Upgradeable {
    // Set the strategy for the vault to use.
    function setStrategy(IStrategy strategy) external;

    // Returns the number of tokens the vault supports
    function tokenCount() external view returns (uint256 count);

    // Gets a token supported by the vault by its index.
    // Reverts if the index is not less than the token count.
    function tokenByIndex(uint256 index) external view returns (IERC20 token);

    // Previews the amount of shares the sender will receive for depositing the given tokens.
    function previewDeposit(uint256[] calldata amount)
        external
        view
        returns (uint256 shares);

    // Deposits senders funds in exchange for shares.
    // !! It is important that the tokens supported match the correct ratios or else additional funds deposited will be lost. !!
    // Reverts if sender does not have appropriate funds or has not allocated allowance.
    function deposit(uint256[] calldata amount)
        external
        returns (uint256 shares);

    // Previews the amount of tokens a  for redeeming a given amount of shares.
    function previewRedeem(uint256 shares)
        external
        view
        returns (uint256[] calldata amount);

    // Redeem shares from the sender for an underlying amount of tokens
    // Reverts if sender does not have appropriate shares.
    function redeem(uint256 shares)
        external
        returns (uint256[] calldata amount);

    // Get the underlying balance of the specified token owned by the vault.
    function balance(IERC20 token) external returns (uint256 amount);

    // Deposit all funds from the vault into the strategy.
    function depositAllIntoStrategy() external;

    // Withdraw all funds from the strategy into the vault.
    function withdrawAllFromStrategy() external;

    event Deposit(address indexed caller, uint256[] amount, uint256 shares);
    event Redeem(address indexed caller, uint256 shares, uint256[] amount);
}
