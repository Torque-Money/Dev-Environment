//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Oracle/IOracle.sol";
import "./MarginLongCore.sol";

abstract contract MarginLongRepayCore is MarginLongCore {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Check whether or not a given borrowed asset is at a loss or profit
    function _repayIsPayout(address token_, address account_) internal view returns (bool) {
        uint256 currentPrice = IOracle(oracle).priceMin(token_, borrowed(token_, account_));
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 _interest = interest(token_, account_);

        return (currentPrice > initialPrice.add(_interest));
    }

    // Get the repay amount when there is a payout
    function _repayPayoutAmount(address token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = IOracle(oracle).priceMin(token_, borrowed(token_, account_));
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 _interest = interest(token_, account_);

        return IOracle(oracle).amountMin(token_, currentPrice.sub(initialPrice).sub(_interest));
    }

    // Get the repay price when there is a loss
    function _repayLossesPrice(address token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = IOracle(oracle).priceMin(token_, borrowed(token_, account_));
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 _interest = interest(token_, account_);

        return initialPrice.add(_interest).sub(currentPrice);
    }

    // Repay a payout amount
    function _repayPayout(address token_, address account_) internal {
        uint256 payoutAmount = _repayPayoutAmount(token_, account_);

        _resetBorrowed(token_, account_);

        LPool(pool).withdraw(token_, payoutAmount);

        _setCollateral(token_, collateral(token_, account_).add(payoutAmount), account_);
    }

    // Repay the payout amounts
    function _repayPayoutAll(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) if (_repayIsPayout(borrowedTokens[i], account_)) _repayPayout(borrowedTokens[i], account_);
    }

    // Repay debt using an accounts collateral
    function _repayLossFromCollateral(
        uint256 debt_,
        address account_,
        address[] memory collateralToken_,
        uint256[] memory collateralRepayAmount_,
        uint256 collateralIndex_
    ) internal returns (uint256) {
        while (debt_ > 0 && collateralIndex_ < collateralToken_.length) {
            uint256 collateralAmount = collateral(collateralToken_[collateralIndex_], account_);
            uint256 collateralPrice = IOracle(oracle).priceMin(collateralToken_[collateralIndex_], collateral(collateralToken_[collateralIndex_], account_));

            if (collateralPrice < debt_) {
                collateralRepayAmount_[collateralIndex_] = collateralAmount;
                _setCollateral(collateralToken_[collateralIndex_], 0, account_);

                debt_ = debt_.sub(collateralPrice);
                collateralIndex_ = collateralIndex_.add(1);
            } else {
                uint256 newAmount = IOracle(oracle).amountMax(collateralToken_[collateralIndex_], debt_);
                if (newAmount > collateralAmount) newAmount = collateralAmount;

                collateralRepayAmount_[collateralIndex_] = newAmount;
                _setCollateral(collateralToken_[collateralIndex_], collateralAmount.sub(newAmount), account_);

                break;
            }
        }

        return collateralIndex_;
    }

    // Repay a loss for a given token
    function _repayLoss(address token_, address account_) internal {
        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts = new uint256[](collateralTokens.length);

        uint256 debt = _repayLossesPrice(token_, account_);
        _repayLossFromCollateral(debt, account_, collateralTokens, collateralRepayAmounts, 0);

        _deposit(collateralTokens, collateralRepayAmounts);

        _resetBorrowed(token_, account_);
    }

    // Pay of all of the losses using collateral
    function _repayLossAll(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts = new uint256[](collateralTokens.length);
        uint256 collateralIndex = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            uint256 debt = _repayLossesPrice(borrowedTokens[i], account_);
            collateralIndex = _repayLossFromCollateral(debt, account_, collateralTokens, collateralRepayAmounts, collateralIndex);
        }

        _deposit(collateralTokens, collateralRepayAmounts);

        _resetBorrowed(account_);
    }

    // Tax an accounts collateral and return the amounts taken from the collateral
    function _taxAccount(uint256 amount_, address account_) internal returns (address[] memory, uint256[] memory) {
        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralRepayAmounts = new uint256[](collateralTokens.length);
        uint256 collateralIndex = 0;

        _repayLossFromCollateral(amount_, account_, collateralTokens, collateralRepayAmounts, collateralIndex);

        return (collateralTokens, collateralRepayAmounts);
    }

    // Deposit collateral into the pool
    function _deposit(address[] memory token_, uint256[] memory amount_) internal {
        for (uint256 i = 0; i < token_.length; i++) {
            if (amount_[i] > 0) {
                IERC20Upgradeable(token_[i]).safeApprove(address(pool), amount_[i]);
                LPool(pool).deposit(token_[i], amount_[i]);
            }
        }
    }

    // Remove borrowed position for an account
    function _resetBorrowed(address token_, address account_) internal {
        LPool(pool).unclaim(token_, borrowed(token_, account_));
        _setInitialBorrowPrice(token_, 0, account_);
        _setBorrowed(token_, 0, account_);

        if (!isBorrowing(account_)) _removeAccount(account_);
    }

    // Reset the users borrowed amounts
    function _resetBorrowed(address account_) internal {
        address[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) _resetBorrowed(borrowedTokens[i], account_);
    }

    function liquidationFeePercent() public view virtual returns (uint256, uint256);

    event Repay(address indexed account, address token);
    event RepayAll(address indexed account);
    event Reset(address indexed account, address resetter);
}
