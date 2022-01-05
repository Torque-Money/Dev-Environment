//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../lib/FractionMath.sol";
import "./LPoolCore.sol";

abstract contract LPoolTax is LPoolCore {
    FractionMath.Fraction private _taxPercent;
    address public taxAccount;

    constructor(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
        taxAccount = _msgSender();
    }

    // Get the tax percentage
    function taxPercentage() public view returns (uint256, uint256) {
        return (_taxPercent.numerator, _taxPercent.denominator);
    }

    // Set the tax percentage
    function setTaxPercentage(
        uint256 taxPercentNumerator_,
        uint256 taxPercentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Set the tax account
    function setTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        taxAccount = account_;
    }
}
