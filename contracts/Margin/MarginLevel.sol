//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./MarginAccount.sol";

abstract contract MarginLevel is Initializable, MarginAccount {
    using SafeMath for uint256;

    FractionMath.Fraction private _minMarginLevel; // Percentage that the margin level may hover above before liquidation (should be above 100)

    function initializeMarginLevel(uint256 minMarginLevelNumerator_, uint256 minMarginLevelDenominator_) public initializer {
        _minMarginLevel.numerator = minMarginLevelNumerator_;
        _minMarginLevel.denominator = minMarginLevelDenominator_;
    }

    // Get the minimum margin level before liquidation (numerator, denominator)
    function minMarginLevel() public view returns (uint256, uint256) {
        return (_minMarginLevel.numerator, _minMarginLevel.denominator);
    }

    // Set the min margin level percent threshold before liquidation
    function setMinMarginLevel(uint256 minMarginLevelNumerator_, uint256 minMarginLevelDenominator_) external onlyOwner {
        _minMarginLevel.numerator = minMarginLevelNumerator_;
        _minMarginLevel.denominator = minMarginLevelDenominator_;
    }

    // Get the margin level of an account
    function marginLevel(address account_) public view returns (uint256, uint256) {
        uint256 totalInitialBorrowPrice = initialBorrowPrice(account_);
        uint256 _interest = interest(account_);
        uint256 _borrowedPrice = borrowedPrice(account_);
        uint256 _collateralPrice = collateralPrice(account_);

        return (_borrowedPrice.add(_collateralPrice), totalInitialBorrowPrice.add(_interest));
    }

    // Check whether an account is liquidatable
    function liquidatable(address account_) public view returns (bool) {
        if (!isBorrowing(account_)) return false;

        (uint256 marginLevelNumerator, uint256 marginLevelDenominator) = marginLevel(account_);

        uint256 lhs = _minMarginLevel.numerator.mul(marginLevelDenominator);
        uint256 rhs = marginLevelNumerator.mul(_minMarginLevel.denominator);

        return lhs >= rhs;
    }
}
