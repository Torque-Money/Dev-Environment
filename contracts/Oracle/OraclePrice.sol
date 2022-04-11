//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FractionMath} from "../lib/FractionMath.sol";

import {OracleApproved} from "./OracleApproved.sol";
import {IOracle} from "./IOracle.sol";

abstract contract OraclePrice is OracleApproved {
    using SafeMathUpgradeable for uint256;
    using FractionMath for FractionMath.Fraction;

    // Get the price of an asset in terms of the default stablecoin
    function _price(address token_, uint256 amount_) internal view virtual returns (uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed(token_));
        (, int256 result, , , ) = feed.latestRoundData();
        uint256 _decimals = feed.decimals();

        if (result <= 0) return 0;
        return uint256(result).mul(10**priceDecimals()).mul(amount_).div(10**_decimals).div(10**decimals(token_));
    }

    // Get the price for a given token amount at the lowest threshold by the oracle
    function priceMin(address token_, uint256 amount_) public view virtual onlyApproved(token_) returns (uint256) {
        (uint256 thresholdNumerator, uint256 thresholdDenominator) = threshold();
        FractionMath.Fraction memory complement = FractionMath.create(1, 1).sub(FractionMath.create(thresholdNumerator, thresholdDenominator));

        return _price(token_, amount_).mul(complement.numerator).div(complement.denominator);
    }

    // Get the price for a given token amount at the highest threshold by the oracle
    function priceMax(address token_, uint256 amount_) public view virtual onlyApproved(token_) returns (uint256) {
        (uint256 thresholdNumerator, uint256 thresholdDenominator) = threshold();
        FractionMath.Fraction memory multiplier = FractionMath.create(1, 1).add(FractionMath.create(thresholdNumerator, thresholdDenominator));

        return _price(token_, amount_).mul(multiplier.numerator).div(multiplier.denominator);
    }

    // Get the amount for a given token price at the lowest threshold by the oracle
    function amountMin(address token_, uint256 price_) public view virtual onlyApproved(token_) returns (uint256) {
        uint256 tokenPrice = OraclePrice.priceMax(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }

    // Get the amount for a given token price at the highest threshold by the oracle
    function amountMax(address token_, uint256 price_) public view virtual onlyApproved(token_) returns (uint256) {
        uint256 tokenPrice = OraclePrice.priceMin(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }
}
