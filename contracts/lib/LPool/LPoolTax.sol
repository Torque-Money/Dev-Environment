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

    /** @dev Set the tax percentage */
    function setTaxPercentage(uint256 _taxPercent) external onlyRole(POOL_ADMIN) {
        taxPercent = _taxPercent;
    }

    /** @dev Set the tax account */
    function setTaxAccount(address _account) external onlyRole(POOL_ADMIN) {
        taxAccount = _account;
    }
}