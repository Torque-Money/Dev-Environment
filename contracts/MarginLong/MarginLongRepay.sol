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

    // Get the repay amount and whether it is a repay payout or loss
    function _repayPrice(IERC20 token_, address account_) internal view returns (uint256, bool) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        if (currentPrice > initialPrice.add(interest)) return (currentPrice.sub(initialPrice).sub(interest), true);
        else return (initialPrice.add(interest).sub(currentPrice), false);
    }

    // Get the borrowed assets that were above the price and how much they were repaid
    function _repayPayoutPrices(address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowTokens = _borrowTokens(account_);
        uint256[] memory borrowedRepays = new uint256[](borrowTokens.length);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            (uint256 repayPrice, bool payout) = _repayPrice(borrowedTokens[i], account_);
            if (payout) borrowedRepays[i] = repayPrice;
        }

        return borrowedRepays;
    }

    // Calculate the repay amounts to be paid out from the collateral
    function _repayLossesPrices(uint256[] memory payoutPrices_, address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowTokens = _borrowTokens(account_);
        uint256[] memory borrowDebt = new uint256[](borrowTokens.length);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);
        uint256[] memory collateralDebt = new uint256[](collateralTokens.length);

        uint256 collateralIndex = 0;
        uint256 borrowIndex = 0;

        for (uint256 i = 0; i < borrowTokens.length; i++) {
            if (payoutAmounts_[i] <= 0) {
                (uint256 debt, ) = _repayPrice(borrowTokens[i], account_);

                while (debt > 0) {
                    if (collateralIndex < collateralTokens.length) {
                        uint256 _collateralPrice = oracle.price(collateralTokens[i], collateralAmounts[i]);

                        uint256 _collateralAmount = collateralAmounts[i];
                        if (_collateralPrice > debt) {
                            _collateralAmount = oracle.minAmount(collateralTokens[i], debt);
                            collateralAmounts[i] = collateralAmounts[i].sub(_collateralAmount);
                            collateralDebt[i] = collateralDebt[i].add(_collateralAmount);
                            debt = 0;
                        } else {
                            collateralDebt[i] = collateralDebt[i].add(_collateralAmount);
                            debt = debt.sub(_collateralPrice);
                            collateralIndex = collateralIndex.add(1);
                        }
                    } else {
                        require(borrowIndex < borrowTokens.length, "Not enough collateral to repay");

                        if (payoutAmounts_[borrowIndex] <= 0) borrowIndex = borrowIndex.add(1);
                        else {
                            uint256 _collateralPrice = oracle.price(borrowedTokens[i], payoutAmounts_[i]); // **** We want the amounts but we have been given the prices - it should be amounts shouldnt it
                        }
                    }
                }
            }
        }
    }
}
