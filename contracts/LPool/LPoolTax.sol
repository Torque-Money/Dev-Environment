//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./LPoolCore.sol";

abstract contract LPoolTax is LPoolCore {
    uint256 public taxPercent;
    address public taxAccount;

    constructor(uint256 taxPercent_) {
        taxPercent = taxPercent_;
        taxAccount = _msgSender();
    }

    // Set the tax percentage
    function setTaxPercentage(uint256 taxPercent_) external onlyRole(POOL_ADMIN) {
        taxPercent = taxPercent_;
    }

    // Set the tax account
    function setTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        taxAccount = account_;
    }
}