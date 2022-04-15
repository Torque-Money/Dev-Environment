//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to support the strategy controller.
interface IStrategyController {
    // Check if the strategy is updateable.
    function isUpdateable() external view returns (bool updateable);

    // Update the strategy.
    function update() external;

    event Update(address indexed caller);
}