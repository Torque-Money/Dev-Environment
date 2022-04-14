//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to support the strategy controller core
interface IStrategyControllerCore {
    // Deposit given amount of assets from the vault to the strategy.
    // Reverts if there are not enough funds.
    function deposit(uint256[] calldata amount) external;

    // Deposit all assets from the vault to the strategy.
    function depositAll() external;

    // Withdraw given amount of assets from the strategy to the vault.
    // Reverts if there are not enough funds.
    function withdraw(uint256[] calldata amount) external;

    // Withdraw all assets from the strategy to the vault
    function withdrawAll() external;

    // Get the available amount of assets in the strategy
    function available() external view returns (uint256[] calldata amount);
}