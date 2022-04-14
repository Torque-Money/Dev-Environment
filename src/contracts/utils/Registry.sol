//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IRegistry} from "../interfaces/utils/IRegistry.sol";

contract Registry is IRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _set;

    function add(address entry) external override {
        require(_set.add(entry), "Registry: Cannot add element to registry");
    }

    function remove(address entry) external override {
        require(
            _set.remove(entry),
            "Registry: Cannot remove element from registry"
        );
    }

    function isEntry(address entry)
        external
        view
        override
        returns (bool _isEntry)
    {
        return _set.contains(entry);
    }

    function count() external view override returns (uint256 _count) {
        return _set.length();
    }

    function getByIndex(uint256 index)
        external
        view
        override
        returns (address entry)
    {
        return _set.at(index);
    }
}