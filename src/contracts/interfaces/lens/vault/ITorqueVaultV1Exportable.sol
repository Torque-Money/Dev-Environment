//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to support Torque vault V1 exportable
interface ITorqueVaultV1Exportable {
    // Export a given amount of tokens from the vault
    function export(uint256[] calldata amount) external;

    // Export all tokens from the vault
    function exportAll() external;
}
