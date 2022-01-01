//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./YieldCore.sol";

abstract contract YieldRates is YieldCore {
    using SafeMath for uint256;

    mapping(IERC20 => FractionMath.Fraction) private _rates; 

    // Set the yield rates for tokens on a per block basis
    function setRates(IERC20[] memory tokens_, uint256[] memory rateNumerators_, uint256[] memory rateDenominators_) external onlyOwner {
        for (uint i = 0; i < tokens_.length; i++) {
            _rates[tokens_[i]].numerator = rateNumerators_[i];
            _rates[tokens_[i]].denominator = rateDenominators_[i];
            emit RateChange(tokens_[i], rateNumerators_[i], rateDenominators_[i]);
        }
    }

    // Get the yield rate numerator and denominator for the given token
    function getRate(IERC20 token_) public view returns (uint256, uint256) {
        Fraction memory rate = _rates[token_];
        return (rate.numerator, rate.denominator);
    }

    // Get the yield owed to a given balance
    function _yield(IERC20 token_, uint256 initialStakeBlock_, uint256 staked_) internal view returns (uint256) {
        Fraction memory rate = _rates[token_];
        return block.number.sub(initialStakeBlock_).mul(staked_).mul(rate.numerator).div(rate.denominator);
    }

    event RateChange(IERC20 token, uint256 rateNumerator, uint256 rateDenominator);
}