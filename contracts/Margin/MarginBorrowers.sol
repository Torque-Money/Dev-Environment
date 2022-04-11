//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract MarginBorrowers {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _accountSet;

    // Add an account to the borrowed list
    function _addAccount(address account_) internal {
        _accountSet.add(account_);
    }

    // Remove an account from the borrowed list
    function _removeAccount(address account_) internal {
        _accountSet.remove(account_);
    }

    // Get a full list of all borrowing accounts
    function getBorrowingAccounts() public view returns (address[] memory) {
        return _accountSet.values();
    }
}
