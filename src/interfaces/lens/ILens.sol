//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IRegistry} from "../utils/IRegistry.sol";

import {IVault} from "./IVault.sol";
import {IStrategy} from "./IStrategy.sol";

// Manages the relationship between a vault and its associated strategies,
// and is responsible for assigning a strategy to a vault.
interface ILens is IRegistry {
    // Get the vault used by the controller.
    function getVault() external view returns (IVault vault);

    // Update the vault and strategy.
    function update(IStrategy strategy) external;
}
