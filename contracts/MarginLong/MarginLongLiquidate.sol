//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Helper for liquidating accounts
    function _liquidateAccount(address account_) internal {
        _resetCollateral(account_);
        _resetBorrowed(account_);
    }

    // Liquidate an account
    function liquidateAccount(address account_) external returns (address[] memory, uint256[] memory) {
        require(liquidatable(account_), "MarginLongLiquidate: This account cannot be liquidated");

        uint256 accountPrice = collateralPrice(account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 fee = accountPrice.mul(liqFeeNumerator).div(liqFeeDenominator);
        (address[] memory collateralTokens, uint256[] memory feeAmounts) = _taxAccount(fee, account_);
        for (uint256 i = 0; i < collateralTokens.length; i++) IERC20Upgradeable(collateralTokens[i]).safeTransfer(_msgSender(), feeAmounts[i]);

        _liquidateAccount(account_);

        emit Liquidated(account_, _msgSender());

        return (collateralTokens, feeAmounts);
    }
}
