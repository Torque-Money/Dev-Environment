//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IRegistry} from "../../utils/IRegistry.sol";

import "../strategy/IStrategy.sol";

// Provides an interface for a contract to support the TWAAPR (time weighted average APR)
interface ITWAAPR is IRegistry {
    // Check if the oracle can be updated
    function isUpdateable() external view returns (bool updateable);

    // Update the oracles APR.
    // Reverts if not updateable.
    function update() external;

    // Get the cumulative time weighted APR for a given strategy.
    // Reverts if strategy is invalid.
    function cumulative(IStrategy strategy) external view returns (uint256 cumulativeAPR);

    // Get the APR for a given strategy.
    // Reverts if strategy is invalid.
    function consult(IStrategy strategy) external view returns (uint256 apr);
}