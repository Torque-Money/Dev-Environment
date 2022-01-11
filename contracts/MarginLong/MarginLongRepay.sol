//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Get the price of the accounts collateral after repaying an account
    function repaidCollateralPrice(address account_) external view returns (uint256) {
        uint256[] memory repayPayoutAmounts = _repayPayoutAmounts(account_);
        (uint256[] memory newRepayPayoutAmounts, , uint256[] memory collateralAmounts, ) = _repayLossesAmounts(repayPayoutAmounts, account_);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        uint256 totalAccountPrice = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            uint256 price = oracle.price(borrowedTokens[i], newRepayPayoutAmounts[i]);
            totalAccountPrice = totalAccountPrice.add(price);
        }

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 price = oracle.price(collateralTokens[i], collateralAmounts[i]);
            totalAccountPrice = totalAccountPrice.add(price);
        }

        return totalAccountPrice;
    }
}
