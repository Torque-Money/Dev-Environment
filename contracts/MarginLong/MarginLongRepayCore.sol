//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../Margin/Margin.sol";

abstract contract MarginLongRepayCore is Margin {
    using SafeMath for uint256;

    FractionMath.Fraction private _repayTax;

    constructor(uint256 repayTaxNumerator_, uint256 repayTaxDenominator_) {
        _repayTax.numerator = repayTaxNumerator_;
        _repayTax.denominator = repayTaxDenominator_;
    }

    // Set the repay tax
    function setRepayTax(uint256 repayTaxNumerator_, uint256 repayTaxDenominator_) external onlyOwner {
        _repayTax.numerator = repayTaxNumerator_;
        _repayTax.denominator = repayTaxDenominator_;
    }

    // Get the repay tax
    function repayTax() public view returns (uint256, uint256) {
        return (_repayTax.numerator, _repayTax.denominator);
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

    // Get the repay amount when there is a loss
    function _repayLossesPrice(IERC20 token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        return initialPrice.add(interest).sub(currentPrice);
    }

    // Get the repay price when there is a loss
    function _repayLossesAmount(IERC20 token_, address account_) internal view returns (uint256) {
        return oracle.amount(token_, _repayLossesPrice(token_, account_));
    }

    // Get the borrowed assets that were above the price and how much they were repaid
    function _repayPayoutAmounts(address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowedRepays = new uint256[](borrowedTokens.length);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            if (_repayIsPayout(borrowedTokens[i], account_)) borrowedRepays[i] = _repayPayoutAmount(borrowedTokens[i], account_);
        }

        return borrowedRepays;
    }

    // Get the amounts of the asset required to repay a loss
    function _repayLossesAmounts(address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowedRepays = new uint256[](borrowedTokens.length);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            if (!_repayIsPayout(borrowedTokens[i], account_)) borrowedRepays[i] = _repayLossesAmount(borrowedTokens[i], account_);
        }

        return borrowedRepays;
    }

    // Get the prices of the assets required to repay a loss
    function _repayLossesPrices(address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowedRepays = new uint256[](borrowedTokens.length);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            if (!_repayIsPayout(borrowedTokens[i], account_)) borrowedRepays[i] = _repayLossesPrice(borrowedTokens[i], account_);
        }

        return borrowedRepays;
    }

    // Payoff the debt using given collateral
    function _repayDebt(
        uint256 debt_,
        IERC20[] memory collateralTokens_,
        uint256[] memory collateralAmounts_,
        uint256[] memory collateralDebt_,
        uint256 index
    ) internal view returns (uint256) {
        uint256 _collateralPrice = oracle.price(collateralTokens_[index], collateralAmounts_[index]);

        if (_collateralPrice > debt_) {
            uint256 _collateralAmount = oracle.amount(collateralTokens_[index], debt_);

            collateralAmounts_[index] = collateralAmounts_[index].sub(_collateralAmount);
            collateralDebt_[index] = collateralDebt_[index].add(_collateralAmount);
        } else {
            uint256 _collateralAmount = collateralAmounts_[index];

            collateralAmounts_[index] = 0;
            collateralDebt_[index] = collateralDebt_[index].add(_collateralAmount);
        }

        return _collateralPrice;
    }

    // Calculate the repay amounts to be paid out from the collateral
    function _repayLossesAmounts(uint256[] memory payoutAmounts_, address account_)
        internal
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowDebt = new uint256[](borrowedTokens.length);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);
        uint256[] memory collateralDebt = new uint256[](collateralTokens.length);

        uint256 collateralIndex = 0;
        uint256 borrowIndex = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            if (payoutAmounts_[i] <= 0) {
                uint256 debt = _repayLossesPrice(borrowedTokens[i], account_);

                while (debt > 0) {
                    if (collateralIndex < collateralTokens.length) {
                        uint256 _collateralPrice = _repayDebt(debt, collateralTokens, collateralAmounts, collateralDebt, collateralIndex);
                        if (_collateralPrice > debt) debt = 0;
                        else {
                            debt = debt.sub(_collateralPrice);
                            collateralIndex = collateralIndex.add(1);
                        }
                    } else {
                        require(borrowIndex < borrowedTokens.length, "Not enough collateral to repay");

                        if (payoutAmounts_[borrowIndex] <= 0) borrowIndex = borrowIndex.add(1);
                        else {
                            uint256 _collateralPrice = _repayDebt(debt, borrowedTokens, payoutAmounts_, borrowDebt, borrowIndex);
                            if (_collateralPrice > debt) debt = 0;
                            else {
                                debt = debt.sub(_collateralPrice);
                                borrowIndex = borrowIndex.add(1);
                            }
                        }
                    }
                }
            }
        }

        return (payoutAmounts_, borrowDebt, collateralAmounts, collateralDebt);
    }

    event Repay(address indexed account, IFlashSwap flashSwap, bytes data);
}
