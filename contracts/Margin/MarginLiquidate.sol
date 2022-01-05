//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginRepay.sol";

abstract contract MarginLiquidate is MarginRepay {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    FractionMath.Fraction private _liquidationFeePercent;

    constructor(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Get the liquidation fee percent
    function liquidationFeePercent() public view returns (uint256, uint256) {
        return (_liquidationFeePercent.numerator, _liquidationFeePercent.denominator);
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) external onlyOwner {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Liquidate all undercollateralized accounts with the remaining collateral
    function _liquidate(address account_, uint256 numPayouts_, IFlashSwap flashSwap_, bytes memory data_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        uint256 numRepays = borrowedTokens.length.sub(numPayouts_);
        IERC20[] memory repayTokens = new IERC20[](numRepays);
        uint256[] memory repayAmounts = new uint256[](numRepays);
        uint256 repayIndex = 0;

        for (uint i = 0; i < borrowedTokens.length; i++) {
            IERC20 token = borrowedTokens[i];

            uint256 amountBorrowed = borrowed(token, account_);
            if (amountBorrowed == 0) continue;

            uint256 currentPrice = borrowedPrice(token, account_);
            uint256 initialPrice = initialBorrowPrice(token, account_);
            uint256 interest = pool.interest(token, initialPrice, initialBorrowBlock(token, account_));

            uint256 repayPrice = initialPrice.add(interest).sub(currentPrice);
            uint256 repayAmount = oracle.amount(token, repayPrice);

            (uint256 liqPercentNumerator, uint256 liqPercentDenominator) = liquidationFeePercent();
            repayTokens[repayIndex] = token;
            repayAmounts[repayIndex] = liqPercentDenominator.sub(liqPercentNumerator).mul(repayAmount).div(liqPercentDenominator);

            repayIndex = repayIndex.add(1);
        }

        IERC20[] memory collateralTokens = _collateralTokens(account_);                     // Swap the collateral for the assets
        uint256[] memory collateralAmounts = new uint256[](collateralTokens.length);
        for (uint i = 0; i < collateralTokens.length; i++) collateralAmounts[i] = collateral(collateralTokens[i], account_);

        uint256[] memory amountOut = _flashSwap(collateralTokens, collateralAmounts, repayTokens, repayAmounts, flashSwap_, data_);
        for (uint i = 0; i < amountOut.length; i++) pool.deposit(repayTokens[i], amountOut[i]); 
    }

    // Liquidate an undercollateralized account
    function liquidate(address account_, IFlashSwap flashSwap_, bytes memory data_) external {
        require(underCollateralized(account_), "Only undercollateralized accounts may be liquidated");

        uint256 numPayouts = _repayPayout(account_);
        _liquidate(account_, numPayouts, flashSwap_, data_);

        emit Liquidated(account_, _msgSender());
    }

    event Liquidated(address indexed account, address liquidator);
}