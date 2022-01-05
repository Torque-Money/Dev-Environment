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
    function _repayPayout(address account_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        for (uint i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 currentPrice = borrowedPrice(token, account_);
            uint256 initialPrice = initialBorrowPrice(token, account_);
            uint256 interest = pool.interest(token, initialPrice, initialBorrowBlock(token, account_));

            if (currentPrice > initialPrice.add(interest)) {
                uint256 payoutAmount = oracle.amount(token, currentPrice.sub(initialPrice).sub(interest));
                pool.unclaim(token, borrowed(token, account_));
                pool.withdraw(token, payoutAmount);
                _setBorrowed(token, 0, account_);
                _setInitialBorrowPrice(token, 0, account_);
            }
        }
    }

    // Get the amounts of each borrowed asset that needs to be repaid
    function _repayAmounts(address account_) internal view returns (IERC20[] memory, uint256[] memory, uint256) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        IERC20[] memory repayTokens = new IERC20[](borrowedTokens.length);
        uint256[] memory repayAmounts = new uint256[](borrowedTokens.length);

        uint256 totalRepayPrice = 0;

        for (uint i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 currentPrice = borrowedPrice(token, account_);
            uint256 initialPrice = initialBorrowPrice(token, account_);
            uint256 interest = pool.interest(token, initialPrice, initialBorrowBlock(token, account_));

            uint256 repayPrice = initialPrice.add(interest).sub(currentPrice);
            uint256 repayAmount = oracle.amount(token, repayPrice);

            repayTokens[i] = token;
            repayAmounts[i] = repayAmount;

            totalRepayPrice = totalRepayPrice.add(repayPrice);
        }

        return (repayTokens, repayAmounts, totalRepayPrice);
    }

    // Repay the losses incurred by the account
    function _repayLosses(address account_) internal {
        (IERC20[] memory repayTokens, uint256[] memory repayAmounts, uint256 totalRepayPrice) = _repayAmounts(account_);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        for (uint i = 0; i < collateralTokens.length; i++) {
            if (totalRepayPrice == 0) break; // **** Add this change to the cleaned up flash swap function too

            IERC20 token = collateralTokens[i];
            uint256 tokenAmount = collateral(token, account_);

            uint256 tokenPrice = collateralPrice(token, account_);
            if (tokenPrice > totalRepayPrice) {                            // Amount of collateral exceeds amount to be repaid
                uint256 correctedTokenAmount = totalRepayPrice.mul(tokenAmount).div(tokenPrice);
                // **** Now we simply just need to add this to the list as well as the token of which it is
                // **** DO NOT FORGET TO UPDATE THE COLLATERAL AMOUNTS as well as the repay price

            } else {                                                        // Amount of collateral does not exceed amount to be repaid

                // **** Simply just add the full amount of the token

            }
        }
    }

    // Repay the accounts borrowed amounts
    function repay(IFlashSwap flashSwap_, bytes memory data_) external {
        require(isBorrowing(_msgSender()), "Cannot repay an account that has not borrowed");

        // **** So my first step is going to be to iterate through everything and look at the gains that have been made
        // **** Once I have iterated through all of these, I will next have to look at the amount of each that will have to be used to be repaid (try putting this in the oracle)

        emit Repay(_msgSender(), flashSwap_, data_);
    }

    event Repay(address indexed account, IFlashSwap flashSwap, bytes data);
}