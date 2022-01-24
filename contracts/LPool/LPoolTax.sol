//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../lib/Set.sol";
import "./LPoolCore.sol";

abstract contract LPoolTax is LPoolCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Set for Set.AddressSet;

    FractionMath.Fraction private _taxPercent;
    Set.AddressSet private _taxAccountSet;

    constructor(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Get the tax percentage
    function taxPercentage() public view returns (uint256, uint256) {
        return (_taxPercent.numerator, _taxPercent.denominator);
    }

    // Set the tax percentage
    function setTaxPercentage(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) external onlyRole(POOL_ADMIN) {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Add a text account
    function addTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.insert(account_);
    }

    // Remove a tax account
    function removeTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.remove(account_);
    }

    // Apply and distribute tax
    function _payTax(IERC20 token_, uint256 amountIn_) internal returns (uint256) {
        address[] memory taxAccounts = _taxAccountSet.iterable();

        uint256 tax = _taxPercent.numerator.mul(amountIn_).div(_taxPercent.denominator).div(taxAccounts.length);
        uint256 totalTax = tax.mul(taxAccounts.length);

        for (uint256 i = 0; i < taxAccounts.length; i++) token_.safeTransfer(taxAccounts[i], tax);

        return totalTax;
    }
}
