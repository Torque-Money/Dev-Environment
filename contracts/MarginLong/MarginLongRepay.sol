//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Helper to repay account
    function _repayAccount(address account_) internal {
        _repayPayouts(account_);
        _repayCollateral(account_);
        _removeAccount(account_);
    }

    // Repay an account
    function repayAccount() external {
        require(isBorrowing(_msgSender()), "MarginLongRepay: Cannot repay account with no leveraged positions");

        _repayAccount(_msgSender());

        emit Repay(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external returns (IERC20[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccount(account_);

        uint256 accountPrice = collateralPrice(account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 penalty = accountPrice.mul(liqFeeNumerator).div(liqFeeDenominator);

        (IERC20[] memory collateralTokens, uint256[] memory feeAmounts) = _taxAccount(penalty, _msgSender());
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralTokens[i].safeTransfer(_msgSender(), feeAmounts[i]);

        emit Reset(account_, _msgSender());

        return (collateralTokens, feeAmounts);
    }
}
