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

    // **** Steps of liquidating:
    // **** - Calculate the amounts of profit that the account has earned (will eventually be liquidated)
    // **** - Calculate the prices of the assets lost and how much percentage of the collateral should be put into each asset to compensate the loss
    // **** - Have the liquidator make the swap and allow them to keep a percentage of the collateral

    // Calculate the amounts of each borrowed asset to convert to
    function _repayConversions(uint256[] memory payoutAmounts_, address account_) internal view {
        // **** First I need to repay off the gains, get the amounts out, in addition to my collateral to get my total repay price

        uint256[] memory repayPrices = _repayLossesPrices(account_);
        uint256 totalRepayLoss = 0;
        for (uint256 i = 0; i < repayPrices.length; i++) {
            totalRepayLoss = totalRepayLoss.add(repayPrices[i]);
        }
    }

    event Liquidated(address indexed account, address liquidator, IFlashSwap flashSwap, bytes data);
}
