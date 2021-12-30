//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginLevel.sol";
import "../FlashSwap/IFlashSwap.sol";

abstract contract IsolatedMarginRepay is IsolatedMarginLevel {
    using SafeMath for uint256;

    // Get the accounts collateral price after repay
    function collateralPriceAfterRepay(IERC20 borrowed_, address account_) public view returns (uint256) {
        uint256 _collateral = collateral(borrowed_, account_);
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));

        return _collateral.add(currentBorrowPrice).sub(initialBorrowPrice).sub(interest);
    }

    // Repay when the collateral price is less than or equal
    function _repayLessOrEqual(IERC20 borrowed_, address account_) internal {
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));

        pool.unclaim(borrowed_, borrowed(borrowed_, account_));

        uint256 repayPrice = initialBorrowPrice.add(interest).sub(currentBorrowPrice);
        IERC20[] memory ownedTokens = collateralTokens(borrowed_, account_);
        for (uint i = 0; i < ownedTokens.length; i++) {
            uint256 price = collateralPrice(borrowed_, ownedTokens[i], account_);
            // if (price <= repayPrice) // **** We need to make sure that we have enough to satisfy the overcollateralized threshold but not too much
        }
    }

    // Repay when the collateral price is higher
    function _repayGreater(IERC20 borrowed_, address account_) internal {

    }

    // Repay a users account with custom flash swap
    function repay(IERC20 borrowed_, IFlashSwap flashSwap_, bytes memory data_) public {
        require(borrowed(borrowed_, _msgSender()) > 0, "Cannot repay an account that has no debt");

        uint256 newCollateralPrice = collateralPriceAfterRepay(borrowed_, _msgSender());
        if (newCollateralPrice <= collateralPrice(borrowed_, _msgSender())) _repayLessOrEqual(borrowed_, _msgSender());
        else _repayGreater(borrowed_, _msgSender());

        _setInitialBorrowPrice(borrowed_, 0, _msgSender());
        _setBorrowed(borrowed_, 0, _msgSender());

        emit Repay(_msgSender(), borrowed_, newCollateralPrice, flashSwap_, data_);
    }

    // Repay a users accounts
    function repay(IERC20 borrowed_) external {
        repay(borrowed_, defaultFlashSwap, ""); 
    }

    event Repay(address indexed account, IERC20 borrowed, uint256 newCollateralPrice, IFlashSwap flashSwap, bytes data);
}