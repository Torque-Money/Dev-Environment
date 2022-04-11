//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../lib/FractionMath.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {LPoolCore} from "./LPoolCore.sol";

abstract contract LPoolTax is Initializable, LPoolCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _taxPercent;
    EnumerableSetUpgradeable.AddressSet private _taxAccountSet;

    function initializeLPoolTax(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) public initializer {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Set the tax percentage
    function setTaxPercentage(uint256 taxPercentNumerator_, uint256 taxPercentDenominator_) external onlyRole(POOL_ADMIN) {
        _taxPercent.numerator = taxPercentNumerator_;
        _taxPercent.denominator = taxPercentDenominator_;
    }

    // Get the tax percentage
    function taxPercentage() public view returns (uint256, uint256) {
        return _taxPercent.export();
    }

    // Add a text account
    function addTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.add(account_);
    }

    // Remove a tax account
    function removeTaxAccount(address account_) external onlyRole(POOL_ADMIN) {
        _taxAccountSet.remove(account_);
    }

    // Apply and distribute tax
    function _payTax(address token_, uint256 amountIn_) internal returns (uint256) {
        address[] memory taxAccounts = _taxAccountSet.values();

        uint256 tax = _taxPercent.numerator.mul(amountIn_).div(_taxPercent.denominator).div(taxAccounts.length);
        uint256 totalTax = tax.mul(taxAccounts.length);

        for (uint256 i = 0; i < taxAccounts.length; i++) IERC20Upgradeable(token_).safeTransfer(taxAccounts[i], tax);

        return totalTax;
    }
}
