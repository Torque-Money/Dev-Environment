//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Controls a vault and what strategy it should implement.
interface IStrategyController {
    // Check if the strategy can be updated.
    function isStrategyUpdateable() external view returns (bool updateable);

    // Update the strategy.
    // Reverts if the strategy is not upgradeable.
    function updateStrategy() external;

    // Check if the APY can be updated.
    function isAPYUpdateable() external view returns (bool updateable);

    // Update the APY.
    // Reverts if the APY is not upgradeable.
    function updateAPY() external;

    event UpdateStrategy(address indexed caller);
    event UpdateAPY(address indexed caller);
}
