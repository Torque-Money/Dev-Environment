//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "../Margin/Margin.sol";

abstract contract MarginLongRepayOLD is Margin {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    FractionMath.Fraction private _repayTax;

    constructor(uint256 repayTaxNumerator_, uint256 repayTaxDenominator_) {
        repayTax.numerator = repayTaxNumerator_;
        repayTax.denominator = repayTaxDenominator_;
    }

    // Set the repay tax
    function setRepayTax(uint256 repayTaxNumerator_, uint256 repayTaxDenominator_) external onlyOwner {
        repayTax.numerator = repayTaxNumerator_;
        repayTax.denominator = repayTaxDenominator_;
    }

    // Get the repay tax
    function repayTax() public view returns (uint256, uint256) {
        return (repayTax.numerator, repayTax.denominator);
    }

    // Check whether or not a given borrowed asset is at a loss or profit
    function _repayIsPayout(IERC20 token_, address account_) internal view returns (bool) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));
        return (currentPrice > initialPrice.add(interest));
    }

    // Get the repay amount when there is a payout
    function _repayPayoutAmount(IERC20 token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        return oracle.amount(token_, currentPrice.sub(initialPrice).sub(interest));
    }

    // Get the repay price when there is a loss
    function _repayLossesPrice(IERC20 token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        return oracle.amount(token_, initialPrice.add(interest).sub(currentPrice));
    }

    // Get the borrowed assets that were above the price and how much they were repaid
    function _repayPayoutAmounts(address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowTokens = _borrowTokens(account_);
        uint256[] memory borrowedRepays = new uint256[](borrowTokens.length);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            if (_repayIsPayout(borrowedTokens[i], account_)) borrowedRepays[i] = _repayPayoutAmount(borrowedTokens[i], account_);
        }

        return borrowedRepays;
    }

    // **** Helper to update the accumulated debt during the repay losses amounts function (**** MAKE SURE TO CHECK IF FUNCTION ARGS ARE IMMUTABLE OR NOT)

    // Calculate the repay amounts to be paid out from the collateral
    function _repayLossesAmounts(uint256[] memory payoutAmounts_, address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowTokens = _borrowTokens(account_);
        uint256[] memory borrowDebt = new uint256[](borrowTokens.length);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);
        uint256[] memory collateralDebt = new uint256[](collateralTokens.length);

        uint256 collateralIndex = 0;
        uint256 borrowIndex = 0;

        for (uint256 i = 0; i < borrowTokens.length; i++) {
            if (payoutAmounts_[i] <= 0) {
                (uint256 debt, ) = _repayLossesPrice(borrowTokens[i], account_);

                while (debt > 0) {
                    if (collateralIndex < collateralTokens.length) {
                        uint256 _collateralPrice = oracle.price(collateralTokens[collateralIndex], collateralAmounts[collateralIndex]);

                        if (_collateralPrice > debt) {
                            uint256 _collateralAmount = oracle.minAmount(collateralTokens[collateralIndex], debt);

                            collateralAmounts[collateralIndex] = collateralAmounts[collateralIndex].sub(_collateralAmount);
                            collateralDebt[collateralIndex] = collateralDebt[collateralIndex].add(_collateralAmount);

                            debt = 0;
                        } else {
                            uint256 _collateralAmount = collateralAmounts[collateralIndex];

                            collateralAmounts[collateralIndex] = 0;
                            collateralDebt[collateralIndex] = collateralDebt[collateralIndex].add(_collateralAmount);

                            debt = debt.sub(_collateralPrice);
                            collateralIndex = collateralIndex.add(1);
                        }
                    } else {
                        require(borrowIndex < borrowTokens.length, "Not enough collateral to repay");

                        if (payoutAmounts_[borrowIndex] <= 0) borrowIndex = borrowIndex.add(1);
                        else {
                            uint256 _collateralPrice = oracle.price(borrowedTokens[borrowIndex], payoutAmounts_[borrowIndex]);

                            if (_collateralPrice > debt) {
                                uint256 _collateralAmount = oracle.minAmount(borrowedTokens[borrowIndex], debt);

                                payoutAmounts_[borrowIndex] = payoutAmounts_[borrowIndex].sub(_collateralAmount);
                                borrowDebt[borrowIndex] = borrowDebt[borrowIndex].add(_collateralAmount);

                                debt = 0;
                            } else {
                                uint256 _collateralAmount = payoutAmounts_[borrowIndex];

                                payoutAmounts_[borrowIndex] = 0;
                                borrowDebt[borrowIndex] = borrowDebt[borrowIndex].add(_collateralAmount);

                                debt = debt.sub(_collateralPrice);
                                borrowIndex = borrowIndex.add(1);
                            }
                        }
                    }
                }
            }
        }
    }

    // **** Now I need to return all of the modified items to be used for the eventual updates
    // **** Understand better how well these swaps correlate to the swaps that is a part of the default flash swap
}
