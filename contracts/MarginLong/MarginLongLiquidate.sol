//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    using SafeERC20 for IERC20;

    // Helper for liquidating accounts
    function _liquidateAccount(address account_) internal {
        _resetBorrowed(account_);
        _resetCollateral(account_);
    }

    // Liquidate an account
    function liquidateAccount(address account_) internal {
        require(liquidatable(account_), "This account cannot be liquidated");

        uint256 accountPrice = collateralPrice(account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 fee = liqFeeDenominator.sub(liqFeeNumerator).mul(accountPrice).div(liqFeeDenominator);
        (IERC20[] memory collateralTokens, uint256[] memory feeAmounts) = _taxAccount(fee, account_);
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralTokens[i].safeTransfer(_msgSender(), feeAmounts[i]);

        _liquidateAccount(account_);

        emit Liquidated(account_, _msgSender());
    }
}
