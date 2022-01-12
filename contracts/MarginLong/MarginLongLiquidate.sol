//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Liquidate an undercollateralized account
    function liquidateAccount(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) external {
        require(liquidatable(account_), "Account is not liquidatable");

        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory payoutAmounts = _repayPayoutAmounts(account_);

        uint256[] memory repayAmounts = _repayConversions(payoutAmounts, account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            pool.unclaim(borrowedTokens[i], borrowed(borrowedTokens[i], account_));

            _setBorrowed(borrowedTokens[i], 0, account_);
            _setInitialBorrowPrice(borrowedTokens[i], 0, account_);

            pool.withdraw(borrowedTokens[i], payoutAmounts[i]);
        }

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);

        uint256 swapInLength = collateralTokens.length + borrowedTokens.length;
        IERC20[] memory swapTokensIn = new IERC20[](swapInLength);
        uint256[] memory swapAmountsIn = new uint256[](swapInLength);
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            swapTokensIn[i] = collateralTokens[i];
            swapAmountsIn[i] = collateralAmounts[i];
        }

        uint256 offset = collateralTokens.length;
        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            swapTokensIn[offset + i] = borrowedTokens[i];
            swapAmountsIn[offset + i] = payoutAmounts[i];
        }

        uint256[] memory amountsOut = _flashSwap(swapTokensIn, swapAmountsIn, borrowedTokens, repayAmounts, flashSwap_, data_);
        for (uint256 i = 0; i < amountsOut.length; i++) {
            borrowedTokens[i].safeApprove(address(pool), amountsOut[i]);
            pool.deposit(borrowedTokens[i], amountsOut[i]);
        }

        _removeAccount(account_);

        emit Liquidated(account_, _msgSender(), flashSwap_, data_);
    }

    // Repay an account that does not meet the collateral requirements
    function resetAccount(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) external {
        // **** We are simply going to repay the account for the user and then payout a chunk of their collateral to the resetter

        // **** The real question is how are we going to pay the user out
        // - We could overpay the accounts collateral (this seems like a pain)
        // - We could just pay out the liquidation fee percentage that we would of had from otherwise swap repaying regularly (so now we are losing assets because of this ?)
        // - ^ Same goes with the liquidation - we technically lose assets (it probably isnt that big of a deal)

        require(resettable(account_), "Account cannot be reset");
    }
}
