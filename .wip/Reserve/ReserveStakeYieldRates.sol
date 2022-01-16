//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./ReserveCore.sol";

abstract contract ReserveStakeYieldRates is ReserveCore {
    using SafeMath for uint256;

    mapping(IERC20 => FractionMath.Fraction) private _rates;

    // Set the yield rates for tokens on a per block basis
    function setRates(
        IERC20[] memory token_,
        uint256[] memory rateNumerator_,
        uint256[] memory rateDenominator_
    ) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            _rates[token_[i]].numerator = rateNumerator_[i];
            _rates[token_[i]].denominator = rateDenominator_[i];
        }
    }

    // Get the yield rate numerator and denominator for the given token
    function getRate(IERC20 token_) public view returns (uint256, uint256) {
        FractionMath.Fraction memory rate = _rates[token_];
        return (rate.numerator, rate.denominator);
    }

    // Get the yield owed to a given balance
    function _yield(
        IERC20 token_,
        uint256 initialStakeBlock_,
        uint256 staked_
    ) internal view returns (uint256) {
        (uint256 rateNumerator, uint256 rateDenominator) = getRate(token_);
        return block.number.sub(initialStakeBlock_).mul(staked_).mul(rateNumerator).div(rateDenominator);
    }
}
