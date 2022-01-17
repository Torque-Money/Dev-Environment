//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Helper to repay a single leveraged position
    function _repayAccount(IERC20 borrowed_, address account_) internal {
        if (_repayIsPayout(borrowed_, account_)) _repayPayout(borrowed_, account_);
        else _repayLoss(borrowed_, account_);

        if (!isBorrowing(account_)) _removeAccount(account_);
    }

    // Helper to repay entire account
    function _repayAccountAll(address account_) internal {
        _repayPayoutAll(account_);
        _repayLossAll(account_);
        _removeAccount(account_);
    }

    // Repay a borrowed position in an account
    function repayAccount(IERC20 borrowed_) external {
        require(isBorrowing(borrowed_, _msgSender()), "MarginLongRepay: Cannot repay account with no leveraged position");

        _repayAccount(borrowed_, _msgSender());

        emit Repay(_msgSender(), borrowed_);
    }

    // Repay all borrowed positions in an account
    function repayAccountAll() external {
        require(isBorrowing(_msgSender()), "MarginLongRepay: Cannot repay account with no leveraged positions");

        _repayAccountAll(_msgSender());

        emit RepayAll(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external returns (IERC20[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccountAll(account_);

        uint256 accountPrice = collateralPrice(account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 penalty = accountPrice.mul(liqFeeNumerator).div(liqFeeDenominator);

        (IERC20[] memory collateralTokens, uint256[] memory feeAmounts) = _taxAccount(penalty, _msgSender());
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralTokens[i].safeTransfer(_msgSender(), feeAmounts[i]);

        emit Reset(account_, _msgSender());

        return (collateralTokens, feeAmounts);
    }
}
