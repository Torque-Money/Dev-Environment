//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginLevel.sol";

abstract contract IsolatedMarginRepay is IsolatedMarginLevel {
    using SafeMath for uint256;

    // Get the accounts collateral price after repay
    function collateralAfterRepay(IERC20 borrowed_, address account_) public view returns (uint256) {
        uint256 _collateral = collateral(borrowed_, account_);
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));

        return _collateral.add(currentBorrowPrice).sub(initialBorrowPrice).sub(interest);
    }
}