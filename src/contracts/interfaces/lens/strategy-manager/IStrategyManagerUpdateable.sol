//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to support the strategy manager updateable
interface IStrategyManagerUpdateable {
    // Check if the strategy is updateable
    function isStrategyUpdateable() external view returns (bool isUpdateable);

    // Update the strategy
    function updateStrategy() external;
}