//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IRegistry} from "../interfaces/IRegistry.sol";

contract Registry is IRegistry {
    function add(address entry) external override {}

    function remove(address entry) external override {}

    function isEntry(address entry) external override returns (bool _isEntry) {}

    function count() external override returns (uint256 registryCount) {}

    function getByIndex(uint256 index) external override returns (address registryEntry) {}
}
