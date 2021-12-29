//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginMargin.sol";

abstract contract IsoMarginRepay is IsoMarginMargin {
    using SafeMath for uint256;

    // Get the accounts collateral after a repay
    function collateralAfterRepay(IERC20 collateral_, IERC20 borrowed_) public view returns (uint256) {
        uint256 _collateral = collateral(collateral_, borrowed_, _msgSender());
        uint256 initialBorrowPrice = _initialBorrowPrice(collateral_, borrowed_);
        uint256 currentBorrowPrice = marketLink.swapPrice(borrowed_, borrowed(collateral_, borrowed_, _msgSender()), collateral_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(collateral_, borrowed_));

        return _collateral.add(currentBorrowPrice).sub(initialBorrowPrice).sub(interest);
    }

    function _repayGreater() internal {

    }

    function _repayLessOrEqual() internal {

    }

    // Repay the accounts borrowed amount
    function repay(IERC20 collateral_, IERC20 borrowed_) external {
        
    }

    event Repay();
}