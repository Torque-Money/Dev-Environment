//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginAccount.sol";

abstract contract IsoMarginMargin is IsoMarginAccount {
    using SafeMath for uint256;

    uint256 public minMarginLevel; // Percentage that the margin level may hover above before liquidation (should be above 100)

    // Set the min margin level percent threshold before liquidation
    function setMinMarginLevel(uint256 minMarginLevel_) external onlyOwner {
        minMarginLevel = minMarginLevel_;
    }

    // Return the numerator and denominator of the margin level
    function marginLevel(IERC20 collateral_, IERC20 borrowed_) public view returns (uint256, uint256) {
        uint256 _collateral = collateral(collateral_, borrowed_, _msgSender());
        uint256 initialBorrowPrice = _initialBorrowPrice(collateral_, borrowed_);
        uint256 currentBorrowPrice = marketLink.swapPrice(borrowed_, borrowed(collateral_, borrowed_, _msgSender()), collateral_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(collateral_, borrowed_));

        return (currentBorrowPrice.add(_collateral), initialBorrowPrice.add(interest)); 
    }

    // Check if an account is undercollateralized
    function underCollateralized(IERC20 collateral_, IERC20 borrowed_) public view returns (bool) {
        (uint256 marginNumerator, uint256 marginDenominator) = marginLevel(collateral_, borrowed_);
        uint256 lhs = minMarginLevel.mul(marginDenominator);
        uint256 rhs = marginNumerator.mul(100);

        return lhs >= rhs;
    }
}