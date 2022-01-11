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

        (uint256 taxNumerator, uint256 taxDenominator) = repayTax();

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            uint256 price = oracle.price(borrowedTokens[i], taxDenominator.sub(taxNumerator).mul(newRepayPayoutAmounts[i]).div(taxDenominator));
            totalAccountPrice = totalAccountPrice.add(price);
        }

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 price = oracle.price(collateralTokens[i], collateralAmounts[i]);
            totalAccountPrice = totalAccountPrice.add(price);
        }

        return totalAccountPrice;
    }

    // Repay off the collateral and update the account
    function repayAccount(IFlashSwap flashSwap_, bytes memory data_) external returns (uint256) {
        uint256[] memory repayPayoutAmounts = _repayPayoutAmounts(_msgSender());
        (uint256[] memory newRepayPayoutAmounts, uint256[] memory borrowDebt, uint256[] memory collateralAmounts, uint256[] memory collateralDebt) = _repayLossesAmounts(
            repayPayoutAmounts,
            _msgSender()
        );

        uint256[] memory repayLossesAmounts = _repayLossesAmounts(_msgSender());

        IERC20[] memory collateralTokens = _collateralTokens(_msgSender());
        IERC20[] memory borrowedTokens = _borrowedTokens(_msgSender());

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            pool.unclaim(borrowedTokens[i], borrowed(borrowedTokens[i], _msgSender()));
            _setBorrowed(borrowedTokens[i], 0, _msgSender());
            _setInitialBorrowPrice(borrowedTokens[i], 0, _msgSender());
        }

        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], collateralAmounts[i], _msgSender());

        // Done seperately to the above because it needs to consider the new collateral
        (uint256 taxNumerator, uint256 taxDenominator) = repayTax();
        for (uint256 i = 0; i < borrowedTokens.length; i++)
            _setCollateral(
                borrowedTokens[i],
                collateral(borrowedTokens[i], _msgSender()).add(taxDenominator.sub(taxNumerator).mul(newRepayPayoutAmounts[i]).div(taxDenominator)),
                _msgSender()
            );

        uint256 swapInLength = collateralTokens.length + borrowedTokens.length;
        IERC20[] memory swapTokensIn = new IERC20[](swapInLength);
        uint256[] memory swapAmountsIn = new uint256[](swapInLength);

        for (uint256 i = 0; i < collateralTokens.length; i++) {
            swapTokensIn[i] = collateralTokens[i];
            swapAmountsIn[i] = collateralDebt[i];
        }

        uint256 offset = collateralTokens.length;
        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            swapTokensIn[offset + i] = borrowedTokens[i];
            swapAmountsIn[offset + i] = borrowDebt[i];
        }

        uint256[] memory amountsOut = _flashSwap(swapTokensIn, swapAmountsIn, borrowedTokens, repayLossesAmounts, flashSwap_, data_);
        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            borrowedTokens[i].safeApprove(address(pool), amountsOut[i]);
            pool.deposit(borrowedTokens[i], amountsOut[i]);
        }

        emit Repay(_msgSender(), flashSwap_, data_);

        return collateralPrice(_msgSender());
    }

    event Repay(address indexed account, IFlashSwap flashSwap, bytes data);
}
