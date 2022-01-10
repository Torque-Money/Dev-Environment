//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarginCore.sol";

abstract contract MarginBorrowLimit is MarginCore {
    uint256 public marginBorrowLimitPrice;

    // Set the maximum account margin borrow price
    function setMarginBorrowLimitPrice(uint256 marginBorrowLimitPrice_) external onlyOwner {
        marginBorrowLimitPrice = marginBorrowLimitPrice_;
    }
}
