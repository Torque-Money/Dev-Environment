//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginLevel.sol";
import "../FlashSwap/IFlashSwap.sol";

abstract contract IsolatedMarginRepay is IsolatedMarginLevel {
    using SafeMath for uint256;

    mapping(uint256 => IERC20) private _swapTokens;
    mapping(uint256 => uint256) private _swapTokenAmounts;
    uint256 private _swapTokensLength;

    // Estimate the accounts collateral after repayment
    function realizedCollateralPrice(IERC20 borrowed_, address account_) public view returns (uint256) {
        uint256 _collateral = collateral(borrowed_, account_);
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));

        return _collateral.add(currentBorrowPrice).sub(initialBorrowPrice).sub(interest);
    }

    function _sellOffCollateral(IERC20 borrowed_, address account_, uint256 repayPrice_, IFlashSwap flashSwap_, bytes memory data_) internal returns (uint256) {
        _swapTokensLength = 0;

        IERC20[] memory ownedTokens = collateralTokens(borrowed_, account_);
        for (uint i = 0; i < ownedTokens.length; i++) {
            _swapTokens[i] = ownedTokens[i];
            uint256 price = collateralPrice(borrowed_, ownedTokens[i], account_);
            _swapTokensLength = _swapTokensLength.add(1);

            uint256 collateralAmount = collateral(borrowed_, ownedTokens[i], account_);
            if (price <= repayPrice_) {
                _swapTokenAmounts[i] = collateralAmount;
                _setCollateral(borrowed_, ownedTokens[i], 0, account_);
                repayPrice_ = repayPrice_.sub(collateralAmount);
            } else {
                uint256 amountOut = repayPrice_.mul(collateralAmount).div(price);
                _swapTokenAmounts[i] = amountOut;
                _setCollateral(borrowed_, ownedTokens[i], collateralAmount.sub(amountOut), account_);
                break;
            }
        }

        IERC20[] memory swapTokens = new IERC20[](_swapTokensLength);
        uint256[] memory swapTokenAmounts = new uint256[](_swapTokensLength);
        for (uint i = 0; i < _swapTokensLength; i++) {
            swapTokens[i] = _swapTokens[i];
            swapTokenAmounts[i] = _swapTokenAmounts[i];
        }

        return _flashSwap(swapTokens, swapTokenAmounts, borrowed_, oracle.amount(borrowed_, repayPrice_), flashSwap_, data_);
    }

    // Repay when the collateral price is less than or equal
    function _repayLessOrEqual(IERC20 borrowed_, address account_, IFlashSwap flashSwap_, bytes memory data_) internal {
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));
        pool.unclaim(borrowed_, borrowed(borrowed_, account_));

        uint256 repayPrice = initialBorrowPrice.add(interest).sub(currentBorrowPrice);
        uint256 amountOut = _sellOffCollateral(borrowed_, account_, repayPrice, flashSwap_, data_);

        pool.deposit(borrowed_, amountOut);
    }

    // Repay when the collateral price is higher
    function _repayGreater(IERC20 borrowed_, address account_) internal {
        uint256 initialBorrowPrice = _initialBorrowPrice(borrowed_, account_);
        uint256 currentBorrowPrice = borrowedPrice(borrowed_, account_);
        uint256 interest = pool.interest(borrowed_, initialBorrowPrice, _initialBorrowBlock(borrowed_, account_));
        pool.unclaim(borrowed_, borrowed(borrowed_, account_));

        uint256 payoutPrice = currentBorrowPrice.sub(initialBorrowPrice).sub(interest);
        uint256 payoutAmount = oracle.amount(borrowed_, payoutPrice);

        pool.withdraw(borrowed_, payoutAmount);
        _setCollateral(borrowed_, borrowed_, collateral(borrowed_, borrowed_, account_).add(payoutAmount), account_);
    }

    // Repay a users account with custom flash swap
    function repay(IERC20 borrowed_, IFlashSwap flashSwap_, bytes memory data_) public {
        require(borrowed(borrowed_, _msgSender()) > 0, "Cannot repay an account that has no debt");

        uint256 newCollateralPrice = realizedCollateralPrice(borrowed_, _msgSender());
        if (newCollateralPrice <= collateralPrice(borrowed_, _msgSender())) _repayLessOrEqual(borrowed_, _msgSender(), flashSwap_, data_);
        else _repayGreater(borrowed_, _msgSender());

        _setInitialBorrowPrice(borrowed_, 0, _msgSender());
        _setBorrowed(borrowed_, 0, _msgSender());

        emit Repay(_msgSender(), borrowed_, newCollateralPrice, flashSwap_, data_);
    }

    // Repay a users accounts
    function repay(IERC20 borrowed_) external {
        repay(borrowed_, defaultFlashSwap, ""); 
    }

    event Repay(address indexed account, IERC20 borrowed, uint256 newCollateralPrice, IFlashSwap flashSwap, bytes data);
}