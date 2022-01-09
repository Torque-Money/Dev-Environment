//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginLongRepay.sol";

abstract contract MarginLongLiquidate is MarginLongRepay {
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

    // Calculate the price required to be returned during the liquidation
    function liquidateRepayPrice(address account_) external view returns (uint256) {
        (, , uint256 repayPrice) = _repayLossesAmountsOut(account_);
        return repayPrice;
    }

    // Liquidate all accounts that have not been repaid by the repay greater
    function _liquidate(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = new uint256[](collateralTokens.length);
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralAmounts[i] = collateral(collateralTokens[i], account_);

        (IERC20[] memory repayTokensOut, uint256[] memory repayAmountsOut, ) = _repayLossesAmountsOut(account_);

        uint256[] memory amountOut = _flashSwap(collateralTokens, collateralAmounts, repayTokensOut, repayAmountsOut, flashSwap_, data_);
        for (uint256 i = 0; i < amountOut.length; i++) {
            repayTokensOut[i].safeApprove(address(pool), amountOut[i]);
            pool.deposit(repayTokensOut[i], amountOut[i]);
        }
    }

    // Liquidate an undercollateralized account
    function _liquidateUndercollateralized(
        address account,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        IERC20[] memory borrowTokens = _borrowedTokens(account_);
        uint256[] memory borrowRepayAmounts = new uint256[](borrowTokens.length);

        uint256 collateralTotalPrice = _collateralPrice(collateral_, account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 allocatedRepayPrice = liqFeeDenominator.sub(liqFeeNumerator).mul(collateralTotalPrice).div(borrowTokens.length).div(liqFeeDenominator);

        for (uint256 i = 0; i < borrowTokens.length; i++) {
            borrowRepayAmounts[i] = oracle.amount(borrowTokens[i], allocatedRepayPrice);
        }

        uint256[] memory collateralAmounts = new uint256[](collateralTokens.length);
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralAmounts[i] = collateral(collateralTokens[i], account_);
        uint256[] memory amountOut = _flashSwap(collateralTokens, collateralAmounts, borrowTokens, borrowRepayAmounts, flashSwap_, data_);

        // **** I will have to manually reset the amounts to zero as well
        // **** SPEAKING OF WHICH I AM PRETTY SURE I AM NOT RESETTING THE BORROWED AMOUNTS FOR THE ABOVE ACCOUNTS ****

        // **** Add a collateral amounts function and replace these problems with it
    }

    // Liquidate an undercollateralized account
    function liquidate(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) external {
        require(underCollateralized(account_), "Only undercollateralized accounts may be liquidated");

        _repayPayout(account_);
        _liquidate(account_, flashSwap_, data_);

        _removeAccount(_msgSender());

        emit Liquidated(account_, _msgSender(), flashSwap_, data_);
    }

    event Liquidated(address indexed account, address liquidator, IFlashSwap flashSwap, bytes data);
}
