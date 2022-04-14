//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to support a strategy
interface IStrategy {
    // Deposit a given amount of funds into the strategy.
    // Reverts if there are not enough funds available.
    function deposit(uint256[] calldata amount) external;

    // Deposit all funds into the strategy.
    function depositAll() external;
}