//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Helper to repay a single leveraged position
    function _repayAccount(address token_, address account_) internal {
        if (_repayIsPayout(token_, account_)) _repayPayout(token_, account_);
        else _repayLoss(token_, account_);
    }

    // Helper to repay entire account
    function _repayAccountAll(address account_) internal {
        _repayPayoutAll(account_);
        _repayLossAll(account_);
    }

    // Repay a borrowed position in an account
    function repayAccount(address token_) external onlyBorrowedToken(token_) {
        require(isBorrowing(token_, _msgSender()), "MarginLongRepay: Cannot repay account with no leveraged position");

        _repayAccount(token_, _msgSender());
        require(!resettable(_msgSender()), "MarginLongRepay: Repaying position puts account at risk");

        emit Repay(_msgSender(), token_);
    }

    // Repay all borrowed positions in an account
    function repayAccountAll() external {
        require(isBorrowing(_msgSender()), "MarginLongRepay: Cannot repay account with no leveraged positions");

        _repayAccountAll(_msgSender());

        emit RepayAll(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external returns (address[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccountAll(account_);

        uint256 accountPrice = collateralPrice(account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 penalty = accountPrice.mul(liqFeeNumerator).div(liqFeeDenominator);

        (address[] memory collateralTokens, uint256[] memory feeAmounts) = _taxAccount(penalty, _msgSender());
        for (uint256 i = 0; i < collateralTokens.length; i++) IERC20Upgradeable(collateralTokens[i]).safeTransfer(_msgSender(), feeAmounts[i]);

        emit Reset(account_, _msgSender());

        return (collateralTokens, feeAmounts);
    }
}
