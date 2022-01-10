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
    function _repayAmount(IERC20 token_, address account_) internal view returns (uint256, bool) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        if (currentPrice > initialPrice.add(interest)) return (oracle.amount(token_, currentPrice.sub(initialPrice).sub(interest)), true);
        else return (oracle.amount(token_, initialPrice.add(interest).sub(currentPrice)), false);
    }

    // Get the borrowed assets that were above the price and how much they were repaid
    function _repayPayoutAmounts(address account_)
        internal
        view
        returns (
            IERC20[] memory,
            uint256[] memory,
            IERC20[] memory,
            uint256[] memory
        )
    {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowedAmounts = _borrowedAmounts(account_);

        // **** IN reality this needs to be a set or something that we can iterate through and add our value to
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            (uint256 repayAmount, bool payout) = _repayAmount(borrowedTokens[i], account_);

            if (payout) {
                borrowedAmounts[i] = 0;
            }
        }
    }
}
