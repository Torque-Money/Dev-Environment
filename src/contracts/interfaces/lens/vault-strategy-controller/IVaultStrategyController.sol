//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IVaultV1} from "../vault/IVaultV1.sol";

// Controls a vault and the strategies it can implement.
interface IVaultStrategyController {
    // Get the vault used by the controller.
    function getVault() external view returns (IVaultV1 vault);

    // Check if the APY can be updated.
    function isUpdateable() external view returns (bool updateable);

    // Update the vault and strategy.
    // Reverts if not updateable.
    function update() external;
}
