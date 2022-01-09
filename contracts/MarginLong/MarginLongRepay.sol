//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "../Margin/Margin.sol";

abstract contract MarginLongRepay is Margin {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(uint256 => IERC20[]) private _tempRepayTokens;
    mapping(uint256 => uint256[]) private _tempRepayAmounts;
    uint256 private _tempRepayIndex;

    // Payout the margin profits to the account
    function _repayPayout(address account_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 currentPrice = _borrowedPrice(token, account_);
            uint256 initialPrice = initialBorrowPrice(token, account_);
            uint256 interest = pool.interest(token, initialPrice, initialBorrowBlock(token, account_));

            if (currentPrice > initialPrice.add(interest)) {
                uint256 payoutAmount = oracle.amount(token, currentPrice.sub(initialPrice).sub(interest));

                pool.unclaim(token, borrowed(token, account_));
                pool.withdraw(token, payoutAmount);

                _setBorrowed(token, 0, account_);
                _setInitialBorrowPrice(token, 0, account_);
                _setCollateral(token, collateral(token, account_).add(payoutAmount), account_);
            }
        }
    }

    // Get the repay price when paying out
    function _repayLossesPrice(IERC20 token_, address account_) internal view returns (uint256) {
        uint256 currentPrice = _borrowedPrice(token_, account_);
        uint256 initialPrice = initialBorrowPrice(token_, account_);
        uint256 interest = pool.interest(token_, initialPrice, initialBorrowBlock(token_, account_));

        return initialPrice.add(interest).sub(currentPrice);
    }

    // Get the amounts of each borrowed asset that needs to be repaid
    function _repayLossesAmountsOut(address account_)
        internal
        view
        returns (
            IERC20[] memory,
            uint256[] memory,
            uint256
        )
    {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        IERC20[] memory repayTokens = new IERC20[](borrowedTokens.length);
        uint256[] memory repayAmounts = new uint256[](borrowedTokens.length);

        uint256 totalRepayPrice = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 repayPrice = _repayLossesPrice(token, account_);
            uint256 repayAmount = oracle.amount(token, repayPrice);

            repayTokens[i] = token;
            repayAmounts[i] = repayAmount;

            totalRepayPrice = totalRepayPrice.add(repayPrice);
        }

        return (repayTokens, repayAmounts, totalRepayPrice);
    }

    // Get the amounts of collateral that need to be used to repay
    function _repayLossesAmountsIn(address account_) internal returns (IERC20[] memory, uint256[] memory) {
        (, , uint256 totalRepayPrice) = _repayLossesAmountsOut(account_);

        IERC20[] storage repayTokens = _tempRepayTokens[_tempRepayIndex];
        uint256[] storage repayAmounts = _tempRepayAmounts[_tempRepayIndex];
        _tempRepayIndex = _tempRepayIndex.add(1);

        IERC20[] memory collateralTokens = _collateralTokens(account_);
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            IERC20 token = collateralTokens[i];
            uint256 tokenAmount = collateral(token, account_);

            uint256 tokenPrice = _collateralPrice(token, account_);
            if (tokenPrice > totalRepayPrice) tokenAmount = totalRepayPrice.mul(tokenAmount).div(tokenPrice);

            repayTokens.push(token);
            repayAmounts.push(tokenAmount);

            // **** None of this is right ?
            _setBorrowed(token, 0, account_);
            _setInitialBorrowPrice(token, 0, account_);
            _setCollateral(token, 0, account_);

            if (tokenPrice >= totalRepayPrice) break;
            else totalRepayPrice = totalRepayPrice.sub(tokenPrice);
        }

        return (repayTokens, repayAmounts);
    }

    // Repay the losses incurred by the account
    function _repayLosses(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) internal {
        (IERC20[] memory repayTokensIn, uint256[] memory repayAmountsIn) = _repayLossesAmountsIn(account_);
        (IERC20[] memory repayTokensOut, uint256[] memory repayAmountsOut, ) = _repayLossesAmountsOut(account_);

        uint256[] memory amountOut = _flashSwap(repayTokensIn, repayAmountsIn, repayTokensOut, repayAmountsOut, flashSwap_, data_);
        for (uint256 i = 0; i < amountOut.length; i++) {
            repayTokensOut[i].safeApprove(address(pool), amountOut[i]);
            pool.deposit(repayTokensOut[i], amountOut[i]);
        }
    }

    // Repay the accounts borrowed amounts
    function repay(IFlashSwap flashSwap_, bytes memory data_) external {
        require(isBorrowing(_msgSender()), "Cannot repay an account that has not borrowed");

        _repayPayout(_msgSender());
        _repayLosses(_msgSender(), flashSwap_, data_);

        _removeAccount(_msgSender());

        emit Repay(_msgSender(), flashSwap_, data_);
    }

    event Repay(address indexed account, IFlashSwap flashSwap, bytes data);
}
