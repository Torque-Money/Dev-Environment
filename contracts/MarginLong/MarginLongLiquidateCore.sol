//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "../FlashSwap/IFlashSwap.sol";
import "../Margin/MarginCore.sol";

abstract contract MarginLongLiquidateCore is MarginCore {
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

    // **** Get a function to calculate the amounts as well as the discount provided to the user

    // **** I need a soft liquidation in the case of the max margin level being reached + the minimum collateral level being reached

    event Liquidated(address indexed account, address liquidator, IFlashSwap flashSwap, bytes data);
}
