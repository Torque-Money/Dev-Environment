//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Provides an interface for a contract to hold a registry for other addresses that can be iterated over.
interface IRegistry {
    // Add an entry to the registry. Cannot be a duplicate or else will revert.
    function add(address entry) external;

    // Remove an entry from the registry. Must exist in registry otherwise will revert.
    function remove(address entry) external;

    // Check if an entry is a part of the registry.
    function isEntry(address entry) external view returns (bool _entry);

    // Returns the number of entries in the registry.
    function entryCount() external view returns (uint256 count);

    // Gets an entry in the registry by its index. Must be less than count or else will revert.
    function entryByIndex(uint256 index) external view returns (address entry);

    event Add(address indexed caller, address entry);
    event Remove(address indexed caller, address entry);
}