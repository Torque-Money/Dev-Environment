//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../FlashSwap/IFlashSwap.sol";
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

        return oracle.amountMax(token_, currentPrice.sub(initialPrice).sub(interest));
    }

    // Get the repay amount when there is a loss
    function _repayLossesAmount(IERC20 token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        return oracle.amountMin(token_, initialPrice.add(interest).sub(currentPrice));
    }

    // Repay a payout amount
    function _repayPayout(IERC20 token_, address account_) internal {
        uint256 amountBorrowed = borrowed(token_, account_);
        uint256 payoutAmount = _repayPayoutAmount(token_, account_);

        _setInitialBorrowPrice(token_, 0, account_);
        _setBorrowed(token_, 0, account_);

        pool.unclaim(token_, amountBorrowed);
        pool.withdraw(token_, payoutAmount);
        _setCollateral(token_, collateral(token_, account_).add(payoutAmount), account_);
    }

    // Repay the payout amounts
    function _repayPayouts(address account_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) if (_repayIsPayout(borrowedTokens[i], account_)) _repayPayout(borrowedTokens[i], account_);
    }

    // Repay the amount for a loss

    // Repay the amounts for a loss
    function _repayLosses(address account_) internal {}

    event Repay(address indexed account, IFlashSwap flashSwap, bytes data);
}
