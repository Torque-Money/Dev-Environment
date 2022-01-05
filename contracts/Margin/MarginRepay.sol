//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginLevel.sol";

abstract contract MarginRepay is MarginLevel {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Payout the margin profits to the account
    function _repayPayout(address account_) internal returns (uint256) {
        uint256 numPayouts = 0;

        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        for (uint i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 amountBorrowed = borrowed(token, account_);
            if (amountBorrowed == 0) continue;          

            uint256 currentPrice = borrowedPrice(token, account_);
            uint256 initialPrice = initialBorrowPrice(token, account_);
            uint256 interest = pool.interest(token, initialPrice, initialBorrowBlock(token, account_));

            if (currentPrice > initialPrice.add(interest)) {
                uint256 payoutAmount = oracle.amount(token, currentPrice.sub(initialPrice).sub(interest));
                pool.unclaim(token, amountBorrowed);
                pool.withdraw(token, payoutAmount);
                _setBorrowed(token, 0, account_);
                _setInitialBorrowPrice(token, 0, account_);

                numPayouts = numPayouts.add(1);
            }
        }

        return numPayouts;
    }

    // Repay the losses incurred by the account
    function _repayLosses(address account_, uint256 numPayouts_) internal {
        // **** Now for the tricky part, we need to iterate over the entire account and swap the given assets for amounts that need to be repaid
        // **** We could actually just be lazy here and subtract the collateral manually and then add it to our list of out tokens (might be the best way)

        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        IERC20[] memory collateralTokens = _collateralTokens(account_);

        uint256 numRepays = borrowedTokens.length.add(collateralTokens.length).sub(numPayouts_);
        IERC20[] memory repayTokens = new IERC20[](numRepays);
        uint256[] memory repayAmounts = new uint256[](numRepays);

        for (uint i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 amountBorrowed = borrowed(token, account_);
            if (amountBorrowed == 0) continue;

            uint256 currentPrice = borrowedPrice(token, account_);
            uint256 initialPrice = initialBorrowPrice(token, account_);
            uint256 interest = pool.interest(token, initialPrice, initialBorrowBlock(token, account_));

            // **** Here all I will have to do is calculate the amount of the asset that needs to be returned to compensate
            // **** ^ but what does this mean ?
            // **** I dont think this is going to work - further investigation is required (this theory would suggest we just liquidate everything and dont get collateral back)

            uint256 repayPrice = initialPrice.add(interest).sub(currentPrice);
            uint256 repayAmount = oracle.amount(token, repayPrice);
        }

        // **** Now we will go through and perform the swap
    }

    // Liquidate an undercollateralized account
    function repay(address account_) external {
        require(isBorrowing(account_), "Cannot repay an account that has not borrowed");

        // **** So my first step is going to be to iterate through everything and look at the gains that have been made
        // **** Once I have iterated through all of these, I will next have to look at the amount of each that will have to be used to be repaid (try putting this in the oracle)
    }

    event Repay(address indexed account);
}