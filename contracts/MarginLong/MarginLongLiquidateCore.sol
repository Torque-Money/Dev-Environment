//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../FlashSwap/IFlashSwap.sol";

abstract contract MarginLongLiquidateCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    // Update the users accounts as a result of the liquidations
    function _resetAccount(address account_) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);

        IERC20[] memory borrowTokens = _borrowedTokens(account_);
        for (uint256 i = 0; i < borrowTokens.length; i++) {
            pool.unclaim(borrowTokens[i], borrowed(borrowTokens[i], account_));

            _setBorrowed(borrowTokens[i], 0, account_);
            _setInitialBorrowPrice(borrowTokens[i], 0, account_);
        }

        _removeAccount(_msgSender());
    }

    // Get the amounts of borrowed assets to swap the collateral to
    function _borrowedRepayAmounts(address account_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256[] memory borrowRepayPrices = new uint256[](borrowedTokens.length);
        uint256 totalRepayPrice = 0;

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            uint256 repayPrice = _repayLossesPrice(borrowTokens[i], account_);
            borrowRepayPrices[i] = repayPrice;
            totalPrice = totalPrice.add(repayPrice);
        }

        uint256 _collateralPrice = collateralPrice(account_);

        uint256[] memory borrowRepayAmounts = new uint256[](borrowRepayPrices.length);
        for (uint256 i = 0; i < borrowRepayAmounts.length; i++) {
            uint256 allocatedCollateralPrice = borrowRepayPrices[i].mul(_collateralPrice).div(totalRepayPrice);
            uint256 allocatedCollateralAmount = oracle.amount(allocatedCollateralPrice, borrowedTokens[i]);

            (uint256 liqFeeNum, uint256 liqFeeDenom) = liquidationFeePercent();
            borrowRepayAmounts[i] = liqFeeDenom.sub(liqFeeNum).mul(allocatedCollateralAmount).div(liqFeeDenom);
        }

        return borrowRepayAmounts;
    }

    // Liquidate all accounts that have not been repaid by the repay greater
    function _liquidate(
        address account_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        IERC20[] memory borrowTokens = _borrowedTokens(account_);
        uint256[] memory borrowAmountsOut = _borrowedRepayAmounts(account_);

        uint256[] memory amountOut = _flashSwap(collateralTokens, collateralAmounts, borrowTokens, borrowAmountsOut, flashSwap_, data_);
        for (uint256 i = 0; i < amountOut.length; i++) {
            repayTokensOut[i].safeApprove(address(pool), amountOut[i]);
            pool.deposit(repayTokensOut[i], amountOut[i]);
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

    // **** I need a soft liquidation in the case of the max margin level being reached + the minimum collateral level being reached

    event Liquidated(address indexed account, address liquidator, IFlashSwap flashSwap, bytes data);
}
