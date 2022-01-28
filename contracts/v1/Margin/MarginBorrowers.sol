//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../lib/Set.sol";

abstract contract MarginBorrowers {
    using Set for Set.AddressSet;

    Set.AddressSet private _accountSet;

    // Add an account to the borrowed list
    function _addAccount(address account_) internal {
        _accountSet.insert(account_);
    }

    // Remove an account from the borrowed list
    function _removeAccount(address account_) internal {
        _accountSet.remove(account_);
    }

    // Get a full list of all borrowing accounts
    function getBorrowingAccounts() public view returns (address[] memory) {
        return _accountSet.iterable();
    }
}
