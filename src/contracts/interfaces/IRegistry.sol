//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to hold a registry for other addresses that can be iterated over
interface IRegistry {
    // Add an entry to the registry. Cannot be a duplicate or else will throw
    function add(address entry) external;

    // Remove an entry from the registry. Must exist in registry otherwise will throw
    function remove(address entry) external;

    // Check if an entry is a part of the registry
    function isEntry(address entry) external returns (bool isEntry);

    // Returns the number of entries in the registry
    function count() external returns (uint256 registryCount);

    // Gets an entry in the registry by its index. Must be less than count or else will throw
    function getByIndex(uint256 index) external returns (address registryEntry);
}
