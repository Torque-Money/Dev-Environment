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
        uint256 initialAccountPrice = collateralPrice(_msgSender());

        _repayAccount(_msgSender());

        uint256 finalAccountPrice = collateralPrice(_msgSender());

        if (finalAccountPrice > initialAccountPrice) {
            (uint256 taxNumerator, uint256 taxDenominator) = repayTax();
            uint256 tax = finalAccountPrice.sub(initialAccountPrice).mul(taxNumerator).div(taxDenominator);
            (IERC20[] memory tokens, uint256[] memory amounts) = _taxAccount(tax, _msgSender());
            _deposit(tokens, amounts);
        }

        emit Repay(_msgSender());
    }

    // Reset an account
    function resetAccount(address account_) external returns (IERC20[] memory, uint256[] memory) {
        require(resettable(account_), "MarginLongRepay: This account cannot be reset");

        _repayAccount(account_);

        uint256 accountPrice = collateralPrice(account_);

        (uint256 taxNumerator, uint256 taxDenominator) = repayTax();
        uint256 tax = accountPrice.mul(taxNumerator).div(taxDenominator);
        (IERC20[] memory collateralTokens, uint256[] memory feeAmounts) = _taxAccount(tax, _msgSender()); // **** Remove this tax in favor of extra interest in a winning position off of the current price
        uint256[] memory depositAmounts = new uint256[](collateralTokens.length);

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            depositAmounts[i] = feeAmounts[i];
            feeAmounts[i] = feeAmounts[i].div(2);
            depositAmounts[i] = depositAmounts[i].sub(feeAmounts[i]);

            collateralTokens[i].safeTransfer(_msgSender(), feeAmounts[i]);
        }

        _deposit(collateralTokens, depositAmounts);

        emit Reset(account_, _msgSender());

        return (collateralTokens, feeAmounts);
    }
}
