//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../lib/FractionMath.sol";
import "./OracleTokens.sol";
import "./IOracle.sol";

contract Oracle is IOracle, OracleTokens {
    using SafeMath for uint256;

    FractionMath.Fraction private _threshold;

    constructor(
        uint256 thresholdNumerator_,
        uint256 thresholdDenominator_,
        uint256 priceDecimals_
    ) OracleTokens(priceDecimals_) {
        _threshold.numerator = thresholdNumerator_;
        _threshold.denominator = thresholdDenominator_;
    }

    // Set the price threshold
    function setThreshold(uint256 thresholdNumerator_, uint256 thresholdDenominator_) external onlyOwner {
        _threshold.numerator = thresholdNumerator_;
        _threshold.denominator = thresholdDenominator_;
    }

    // Get the threshold
    function threshold() public view returns (uint256, uint256) {
        return (_threshold.numerator, _threshold.denominator);
    }

    // Get the price of an asset in terms of the default stablecoin
    function _price(IERC20 token_, uint256 amount_) internal view onlySupported(token_) returns (uint256) {
        AggregatorV3Interface feed = priceFeed(token_);
        (, int256 result, , , ) = feed.latestRoundData();
        uint256 _decimals = feed.decimals();

        if (result <= 0) {
            feed = reservePriceFeed(token_);
            (, result, , , ) = feed.latestRoundData();
            _decimals = feed.decimals();
        }
        if (result <= 0) return 0;

        return uint256(result).mul(10**priceDecimals).mul(amount_).div(10**_decimals).div(10**decimals(token_));
    }

    // Get the price for a given token amount at the lowest threshold by the oracle
    function priceMin(IERC20 token_, uint256 amount_) public view override returns (uint256) {
        (uint256 thresholdNumerator, uint256 thresholdDenominator) = threshold();
        return thresholdDenominator.sub(thresholdNumerator).mul(_price(token_, amount_)).div(thresholdDenominator);
    }

    // Get the price for a given token amount at the highest threshold by the oracle
    function priceMax(IERC20 token_, uint256 amount_) public view override returns (uint256) {
        (uint256 thresholdNumerator, uint256 thresholdDenominator) = threshold();
        return (thresholdDenominator).add(thresholdNumerator).mul(_price(token_, amount_)).div(thresholdDenominator);
    }

    // Get the amount for a given token price at the lowest threshold by the oracle
    function amountMin(IERC20 token_, uint256 price_) external view override returns (uint256) {
        uint256 tokenPrice = priceMax(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }

    // Get the amount for a given token price at the highest threshold by the oracle
    function amountMax(IERC20 token_, uint256 price_) external view override returns (uint256) {
        uint256 tokenPrice = priceMin(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }
}
