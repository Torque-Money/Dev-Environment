//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to support a strategy
interface IStrategy {
    // Deposit a given amount of funds into the strategy.
    // Reverts if there are not enough funds available.
    function deposit(uint256[] calldata amount) external;

    // Withdraw a given amount of funds from the strategy.
    // Reverts if there are not enough funds available.
    function withdraw(uint256[] calldata amount) external;

    // Get the balance of funds for a given token in the strategy.
    function balance(address token) external view returns (uint256 amount);
}