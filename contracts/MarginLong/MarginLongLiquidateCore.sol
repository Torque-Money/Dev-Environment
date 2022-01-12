//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongLiquidateCore is MarginLongRepayCore {
    using SafeMath for uint256;

    FractionMath.Fraction private _liquidationFeePercent;

    constructor(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) external onlyOwner {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Get the liquidation fee percent
    function liquidationFeePercent() public view returns (uint256, uint256) {
        return (_liquidationFeePercent.numerator, _liquidationFeePercent.denominator);
    }

    // Calculate the amounts of each borrowed asset to convert to
    function _repayConversions(uint256[] memory payoutAmounts_, address account_) internal view returns (uint256[] memory) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        uint256 totalCollateralPrice = collateralPrice(account_);
        for (uint256 i = 0; i < payoutAmounts_.length; i++) totalCollateralPrice = totalCollateralPrice.add(oracle.price(borrowedTokens[i], payoutAmounts_[i]));

        uint256[] memory repayPrices = _repayLossesPrices(account_);
        uint256 totalRepayLoss = 0;
        for (uint256 i = 0; i < repayPrices.length; i++) totalRepayLoss = totalRepayLoss.add(repayPrices[i]);

        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256[] memory assetRepayAmounts = new uint256[](borrowedTokens.length);
        for (uint256 i = 0; i < borrowedTokens.length; i++)
            assetRepayAmounts[i] = oracle.amount(
                borrowedTokens[i],
                liqFeeDenominator.sub(liqFeeNumerator).mul(repayPrices[i]).div(totalRepayLoss).div(liqFeeDenominator)
            );

        return assetRepayAmounts;
    }

    event Liquidated(address indexed account, address liquidator, IFlashSwap flashSwap, bytes data);
}
