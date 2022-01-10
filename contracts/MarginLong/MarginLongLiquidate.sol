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

    // Check if an account is undercollateralized
    function undercollateralized(address account_) public view returns (bool) {
        (uint256 marginNumerator, uint256 marginDenominator) = marginLevel(account_);
        return marginNumerator <= marginDenominator;
    }

    // Calculate the price required to be returned during the liquidation
    function liquidateRepayPrice(address account_) external view returns (uint256) {
        // **** FIX THIS BROKEN FUNCTION
        // **** **** I NEED TO MAKE SURE I UNCLAIM EVERYWHERE DURING REPAY AND LIQUIDATE TOO
        (, , uint256 repayPrice) = _repayLossesAmountsOut(account_);
        return repayPrice;
    }

    // Update the users accounts as a result of the liquidations
    function _resetAccount(address account_) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);

        IERC20[] memory borrowTokens = _borrowedTokens(account_);
        for (uint256 i = 0; i < borrowTokens.length; i++) {
            _setBorrowed(borrowTokens[i], 0, account_);
            _setInitialBorrowPrice(borrowTokens[i], 0, account_);
        }

        _removeAccount(_msgSender());
    }

    // Liquidate all accounts that have not been repaid by the repay greater
    function _liquidate(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

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
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        IERC20[] memory borrowTokens = _borrowedTokens(account_);
        uint256[] memory borrowRepayAmounts = new uint256[](borrowTokens.length);

        uint256 collateralTotalPrice = _collateralPrice(collateral_, account_);
        (uint256 liqFeeNumerator, uint256 liqFeeDenominator) = liquidationFeePercent();
        uint256 allocatedRepayPrice = collateralTotalPrice.div(borrowTokens.length);

        for (uint256 i = 0; i < borrowTokens.length; i++)
            borrowRepayAmounts[i] = liqFeeDenominator.sub(liqFeeNumerator).mul(oracle.amount(borrowTokens[i], allocatedRepayPrice)).div(liqFeeDenominator);

        uint256[] memory amountOut = _flashSwap(collateralTokens, collateralAmounts, borrowTokens, borrowRepayAmounts, flashSwap_, data_);
        for (uint256 i = 0; i < amountOut.length; i++) {
            borrowTokens[i].safeApprove(address(pool), amountOut[i]);
            pool.deposit(borrowTokens[i], amountOut[i]);
        }
    }

    // Liquidate an undercollateralized account
    function liquidate(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) external {
        require(liquidatable(account_), "Account is not liquidatable");

        _repayPayout(account_);

        _liquidate(account_, flashSwap_, data_);

        _resetAccount(account_);

        emit Liquidated(account_, _msgSender(), flashSwap_, data_);
    }

    event Liquidated(address indexed account, address liquidator, IFlashSwap flashSwap, bytes data);
}
