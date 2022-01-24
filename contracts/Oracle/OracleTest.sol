//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./OracleTokens.sol";
import "./IOracle.sol";

contract OracleTest is IOracle, OracleTokens {
    using SafeMath for uint256;

    mapping(IERC20 => uint256) private _prices;
    uint256 private _priceDecimals;
    FractionMath.Fraction private _threshold;

    constructor(
        uint256 thresholdNumerator_,
        uint256 thresholdDenominator_,
        uint256 priceDecimals_
    ) {
        _threshold.numerator = thresholdNumerator_;
        _threshold.denominator = thresholdDenominator_;
        _priceDecimals = priceDecimals_;
    }

    function priceDecimals() public view returns (uint256) {
        return _priceDecimals;
    }

    function threshold() public view returns (uint256, uint256) {
        return (_threshold.numerator, _threshold.denominator);
    }

    function setPrice(IERC20 token_, uint256 price_) external {
        _prices[token_] = price_;
    }

    function _price(IERC20 token_, uint256 amount_) internal view returns (uint256) {
        return _prices[token_].mul(amount_).div(10**decimals(token_));
    }

    function priceMin(IERC20 token_, uint256 amount_) public view override returns (uint256) {
        return _threshold.denominator.sub(_threshold.numerator).mul(_price(token_, amount_)).div(_threshold.denominator);
    }

    function priceMax(IERC20 token_, uint256 amount_) public view override returns (uint256) {
        return (_threshold.denominator).add(_threshold.numerator).mul(_price(token_, amount_)).div(_threshold.denominator);
    }

    function amountMin(IERC20 token_, uint256 price_) external view override returns (uint256) {
        uint256 tokenPrice = priceMax(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }

    function amountMax(IERC20 token_, uint256 price_) external view override returns (uint256) {
        uint256 tokenPrice = priceMin(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }
}
