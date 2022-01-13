//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../Margin/Margin.sol";

abstract contract MarginLongRepayCore is Margin {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    // Get the repay price when there is a loss
    function _repayLossesPrice(IERC20 token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        return initialPrice.add(interest).sub(currentPrice);
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

    // Repay debt using an accounts collateral
    function _repayDebt(
        uint256 debt_,
        address account_,
        IERC20[] memory collateralTokens_,
        uint256[] memory collateralRepayAmounts_,
        uint256 collateralIndex_
    ) internal returns (uint256) {
        while (debt_ > 0 && collateralIndex_ < collateralTokens_.length) {
            uint256 collateralAmount = collateral(collateralTokens_[collateralIndex_], account_);
            uint256 collateralPrice = _collateralPrice(collateralTokens_[collateralIndex_], account_);

            if (collateralPrice < debt_) {
                collateralRepayAmounts_[collateralIndex_] = collateralAmount;
                _setCollateral(collateralTokens_[collateralIndex_], 0, account_);

                debt_ = debt_.sub(collateralPrice);
                collateralIndex_ = collateralIndex_.add(1);
            } else {
                uint256 newAmount = oracle.amountMax(collateralTokens_[collateralIndex_], collateralPrice);
                if (newAmount > collateralAmount) newAmount = collateralAmount;

                collateralRepayAmounts_[collateralIndex_] = newAmount;
                _setCollateral(collateralTokens_[collateralIndex_], newAmount, account_);

                break;
            }
        }

        return collateralIndex_;
    }

    // Get the collateral repay amounts to pay off a loss
    function _repayCollateralAmounts(address account_) internal returns (IERC20[] memory, uint256[] memory) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowedRepayAmounts = new uint256[](borrowedTokens.length);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts;
        uint256 collateralIndex = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            uint256 debt = _repayLossesPrice(borrowedTokens[i], account_);
            borrowedRepayAmounts[i] = oracle.amountMin(borrowedTokens[i], debt);

            collateralIndex = _repayDebt(debt, account_, collateralTokens, collateralRepayAmounts, collateralIndex);
        }

        return (collateralTokens, collateralRepayAmounts);
    }

    // Tax an account
    function _taxAccount(uint256 amount_, address account_) internal returns (IERC20[] memory, uint256[] memory) {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts;
        uint256 collateralIndex = 0;

        _repayDebt(amount_, account_, collateralTokens, collateralRepayAmounts, collateralIndex);

        return (collateralTokens, collateralRepayAmounts);
    }

    // Deposit collateral into the pool
    function _deposit(IERC20[] memory token_, uint256[] memory amount_) internal {
        for (uint256 i = 0; i < token_.length; i++) {
            token_[i].safeApprove(address(pool), amount_[i]);
            pool.deposit(token_[i], amount_[i]);
        }
    }

    // Repay the in debt collateral
    function _repayCollateral(address account_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        (IERC20[] memory repayCollateralTokens, uint256[] memory repayCollateralAmounts) = _repayCollateralAmounts(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            pool.unclaim(borrowedTokens[i], borrowed(borrowedTokens[i], account_));
            _setBorrowed(borrowedTokens[i], 0, account_);
            _setInitialBorrowPrice(borrowedTokens[i], 0, account_);
        }

        _deposit(repayCollateralTokens, repayCollateralAmounts);
    }

    event Repay(address indexed account);
    event Reset(address indexed account, address resetter);
}
