//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginLongRepayCore} from "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    // Helper to repay a single leveraged position
    function _repayAccount(address token_, address account_) internal {
        if (_repayIsPayout(token_, account_)) _repayPayout(token_, account_);
        else _repayLoss(token_, account_);
    }

    // Helper to repay entire account
    function _repayAccount(address account_) internal {
        _repayPayoutAll(account_);
        _repayLossAll(account_);
    }

    // Repay a borrowed position in an account
    function repayAccount(address token_) external whenNotPaused onlyBorrowToken(token_) {
        require(_isBorrowing(token_, _msgSender()), "MarginLongRepay: Cannot repay account with no leveraged position");

        _repayAccount(token_, _msgSender());
        require(!resettable(_msgSender()), "MarginLongRepay: Repaying position puts account at risk");

        emit Repay(_msgSender(), token_);
    }

    // Repay all borrowed positions in an account
    function repayAccount() external whenNotPaused {
        require(_isBorrowing(_msgSender()), "MarginLongRepay: Cannot repay account with no leveraged positions");

        _repayAccount(_msgSender());

        emit RepayAll(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external whenNotPaused returns (address[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccount(account_);

        (address[] memory collateralTokens, uint256[] memory collateralTax) = _taxAccount(account_, _msgSender());

        emit Reset(account_, _msgSender());

        return (collateralTokens, collateralTax);
    }
}
