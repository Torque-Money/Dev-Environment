//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginAccount.sol";

abstract contract IsolatedMarginLevel is IsolatedMarginAccount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public minMarginLevel; // Percentage that the margin level may hover above before liquidation (should be above 100)

    constructor(uint256 minMarginLevel_) {
        minMarginLevel = minMarginLevel_;
    }

    // Set the min margin level percent threshold before liquidation
    function setMinMarginLevel(uint256 minMarginLevel_) external onlyOwner {
        minMarginLevel = minMarginLevel_;
    }

    // Return the numerator and denominator of the margin level
    function marginLevel(IERC20 borrowed_, address account_) public view returns (uint256, uint256) {
        uint256 accountPrice = collateralPrice(borrowed_, account_);
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = oracle.price(borrowed_, borrowed(borrowed_, account_));
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));

        return (currentBorrowPrice.add(accountPrice), initialBorrowPrice.add(interest)); 
    }

    // Check if an account is undercollateralized
    function underCollateralized(IERC20 borrowed_, address account_) public view returns (bool) {
        (uint256 marginNumerator, uint256 marginDenominator) = marginLevel(borrowed_, account_);
        uint256 lhs = minMarginLevel.mul(marginDenominator);
        uint256 rhs = marginNumerator.mul(100);

        return lhs >= rhs;
    }
}