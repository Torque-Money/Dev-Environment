//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./YieldRates.sol";

abstract contract YieldStake is YieldRates {
    mapping(IERC20 => uint256) private _ratesNumerator; 
    mapping(IERC20 => uint256) private _ratesDenominator; 

    // Set the yield rates for tokens
    function setRates(IERC20[] memory tokens_, uint256[] memory ratesNumerator_, uint256[] memory ratesDenominator_) external onlyOwner {
        for (uint i = 0; i < tokens_.length; i++) {
            _ratesNumerator[tokens_[i]] = ratesNumerator_[i];
            _ratesDenominator[tokens_[i]] = ratesDenominator_[i];
            emit RateChange(tokens_[i], ratesNumerator_[i], ratesDenominator_[i]);
        }
    }

    // Get the yield rate numerator and denominator for the given token
    function getRate(IERC20 token_) public view returns (uint256, uint256) {
        return (_ratesNumerator[token_], _ratesDenominator[token_]);
    }

    event RateChange(IERC20 token, uint256 rateNumerator, uint256 rateDenominator);
}