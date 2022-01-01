//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./IsolatedMarginAccount.sol";

abstract contract IsolatedMarginLevel is IsolatedMarginAccount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    FractionMath.Fraction private _minMarginLevel; // Percentage that the margin level may hover above before liquidation (should be above 100)

    constructor(uint256 minMarginLevelNumerator_, uint256 minMarginLevelDenominator_) {
        _minMarginLevel = minMarginLevel_;
    }

    // Get the min margin level percent
    function minMarginLevel() external view returns (uint256, uint256) {
        return (_minMarginLevel.numerator, _minMarginLevel.denominator);
    }

    // Set the min margin level percent threshold before liquidation
    function setMinMarginLevel(uint256 minMarginLevelNumerator_, uint256 minMarginLevelNumerator_) external onlyOwner {
        minMarginLevel = minMarginLevel_;
    }

    // Return the numerator and denominator of the margin level
    function marginLevel(IERC20 borrowed_, address account_) public view returns (uint256, uint256) {
        uint256 accountPrice = collateralPrice(borrowed_, account_);
        uint256 _initialBorrowPrice = initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, _initialBorrowPrice, initialBorrowBlock(borrowed_, account_));

        return (currentBorrowPrice.add(accountPrice), _initialBorrowPrice.add(interest)); 
    }

    // Check if an account is undercollateralized
    function underCollateralized(IERC20 borrowed_, address account_) public view returns (bool) {
        (uint256 marginNumerator, uint256 marginDenominator) = marginLevel(borrowed_, account_);
        uint256 lhs = _minMarginLevel.numerator.mul(marginDenominator);
        uint256 rhs = marginNumerator.mul(_minMarginLevel.denominator);

        return lhs >= rhs;
    }
}