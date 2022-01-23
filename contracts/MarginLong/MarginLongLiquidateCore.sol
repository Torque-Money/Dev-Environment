//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongLiquidateCore is MarginLongRepayCore {
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
    function liquidationFeePercent() public view override returns (uint256, uint256) {
        return (_liquidationFeePercent.numerator, _liquidationFeePercent.denominator);
    }

    // Reset the accounts collateral
    function _resetCollateral(address account_) internal {
        IERC20[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        _deposit(collateralTokens, collateralAmounts);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], collateralAmounts[i], account_);
    }

    // Reset the users borrowed amounts
    function _resetBorrowed(address account_) internal {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);

        for (uint256 i = 0; i < borrowedTokens.length; i++) {
            pool.unclaim(borrowedTokens[i], borrowed(borrowedTokens[i], account_));
            _setInitialBorrowPrice(borrowedTokens[i], 0, account_);
            _setBorrowed(borrowedTokens[i], 0, account_);

            console.log("Borrowing specific token:");
            console.log(isBorrowing(borrowedTokens[i], account_));
        }

        console.log("Total borrowing:");
        console.log(isBorrowing(account_));

        _removeAccount(account_);
    }

    event Liquidated(address indexed account, address liquidator);
}
