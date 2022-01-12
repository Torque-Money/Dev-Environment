//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    // Helper to repay account
    function _repayAccount(address account_) internal {
        _repayPayouts(_msgSender());
        _repayCollateral(_msgSender());
        _removeAccount(_msgSender());
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
    function resetAccount(address account_) external {
        require(resettable(account_), "This account cannot be reset");

        _repayAccount(account_);

        uint256 accountPrice = collateralPrice(account_);

        (uint256 taxNumerator, uint256 taxDenominator) = repayTax();
        uint256 tax = accountPrice.mul(taxNumerator).div(taxDenominator);
        (IERC20[] memory tokens, uint256[] memory amounts) = _taxAccount(tax, _msgSender());
        for (uint256 i = 0; i < tokens.length; i++) tokens[i].safeTransfer(_msgSender(), amounts[i]);

        emit Reset(account_, _msgSender());
    }
}
