//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IStrategy} from "./IStrategy.sol";
import {ISupportsToken} from "../utils/ISupportsToken.sol";

// A multi-token vault that tracks each users share with its own ERC20 interface. Manages deposited funds using a strategy to earn rewards.
interface IVault is ISupportsToken, IERC20Upgradeable {
    // Set the strategy for the vault to use and ensure funds are transferred properly.
    // New strategy should be different than the old strategy.
    function setStrategy(IStrategy strategy) external;

    // Get the strategy the vault used.
    function getStrategy() external view returns (IStrategy _strategy);

    // Estimates the amount of shares the sender will receive for depositing the given tokens.
    // Not guaranteed to be the exact amount of shares owed - slight variation expected.
    function estimateDeposit(uint256[] calldata amount) external view returns (uint256 shares);

    // Deposits senders funds in exchange for shares.
    // It is important that the tokens supported match the correct ratios or else additional funds deposited will be lost.
    // Reverts if sender does not have appropriate funds or has not allocated allowance.
    function deposit(uint256[] calldata amount) external returns (uint256 shares);

    // Esimates the amount of tokens a  for redeeming a given amount of shares.
    // Not guaranteed to be the exact amount of tokens owed - slight variation expected.
    function estimateRedeem(uint256 shares) external view returns (uint256[] calldata amount);

    // Redeem shares from the sender for an underlying amount of tokens
    // Reverts if sender does not have appropriate shares.
    function redeem(uint256 shares) external returns (uint256[] calldata amount);

    event Deposit(address indexed caller, uint256[] amount, uint256 shares);
    event Redeem(address indexed caller, uint256 shares, uint256[] amount);
}
