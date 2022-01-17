//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./MarginAccount.sol";

abstract contract MarginLevel is MarginAccount {
    using SafeMath for uint256;

    FractionMath.Fraction private _minMarginLevel; // Percentage that the margin level may hover above before liquidation (should be above 100)

    constructor(uint256 minMarginLevelNumerator_, uint256 minMarginLevelDenominator_) {
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
        uint256 interest = interest(account_);
        return (borrowedPrice(account_).add(collateralPrice(account_)), totalInitialBorrowPrice.add(interest));
    }

    // Check whether an account is liquidatable
    function liquidatable(address account_) public view returns (bool) {
        if (!isBorrowing(account_)) return false;

        (uint256 marginNumerator, uint256 marginDenominator) = marginLevel(account_);
        uint256 lhs = _minMarginLevel.numerator.mul(marginDenominator);
        uint256 rhs = marginNumerator.mul(_minMarginLevel.denominator);

        return lhs >= rhs;
    }
}
