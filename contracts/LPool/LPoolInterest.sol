//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./LPoolLiquidity.sol";

abstract contract LPoolInterest is LPoolLiquidity {
    using SafeMath for uint256;

    uint256 public blocksPerCompound;

    mapping(IERC20 => FractionMath.Fraction) private _maxInterestMin;
    mapping(IERC20 => FractionMath.Fraction) private _maxInterestMax;

    mapping(IERC20 => FractionMath.Fraction) private _maxUtilization;

    constructor(uint256 blocksPerCompound_) {
        blocksPerCompound = blocksPerCompound_;
    }

    // Set the blocks per compound
    function setBlocksPerCompound(uint256 blocksPerCompound_) external onlyRole(POOL_ADMIN) {
        blocksPerCompound = blocksPerCompound_;
    }

    // Get the max interest for minimum utilization for the given token
    function maxInterestMin(IERC20 token_) public view returns (uint256, uint256) {
        return (_maxInterestMin[token_].numerator, _maxInterestMin[token_].denominator);
    }

    // Set the max interest for minimum utilization for the given token
    function setMaxInterestMin(
        IERC20[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPA(token_[i])) {
                _maxInterestMin[token_[i]].numerator = percentNumerator_[i];
                _maxInterestMin[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the max interest for maximum utilization for the given token
    function maxInterestMax(IERC20 token_) public view returns (uint256, uint256) {
        return (_maxInterestMax[token_].numerator, _maxInterestMax[token_].denominator);
    }

    // Set the max interest for maximum utilization for the given token
    function setMaxInterestMax(
        IERC20[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPA(token_[i])) {
                _maxInterestMax[token_[i]].numerator = percentNumerator_[i];
                _maxInterestMax[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the max utilization threshold for the given token
    function maxUtilization(IERC20 token_) public view returns (uint256, uint256) {
        return (_maxUtilization[token_].numerator, _maxUtilization[token_].denominator);
    }

    // Set the max utilization threshold for the given token
    function setMaxUtilization(
        IERC20[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPA(token_[i])) {
                _maxUtilization[token_[i]].numerator = percentNumerator_[i];
                _maxUtilization[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Helper to calculate the interest rate when the amount borrowed is above the max utilization rate
    function _interestRateMax(
        uint256 valueLocked,
        uint256 utilized,
        FractionMath.Fraction memory utilization,
        FractionMath.Fraction memory interestMin,
        FractionMath.Fraction memory interestMax
    ) internal pure returns (uint256, uint256) {
        uint256 numerator;
        {
            numerator = utilized.mul(interestMax.numerator).mul(utilization.denominator).mul(interestMin.denominator);
        }
        {
            numerator = numerator.add(utilization.numerator.mul(interestMin.numerator).mul(valueLocked).mul(interestMax.denominator));
        }
        {
            numerator = numerator.mul(utilization.denominator).mul(interestMax.denominator);
        }

        uint256 numeratorSub;
        {
            numeratorSub = utilization.numerator.mul(interestMax.numerator).mul(valueLocked);
        }
        {
            numeratorSub = numeratorSub.mul(interestMax.denominator).mul(utilization.denominator).mul(interestMin.denominator);
        }
        {
            numerator = numerator.sub(numeratorSub);
        }

        uint256 denominator;
        {
            denominator = valueLocked.mul(interestMax.denominator).mul(utilization.denominator);
        }
        {
            denominator = denominator.mul(interestMin.denominator).mul(utilization.denominator).mul(interestMax.denominator);
        }

        return (numerator, denominator);
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 token_) public view returns (uint256, uint256) {
        uint256 valueLocked = tvl(token_);
        uint256 utilized = valueLocked.sub(liquidity(token_));

        FractionMath.Fraction memory utilization = _maxUtilization[token_];
        FractionMath.Fraction memory interestMin = _maxInterestMin[token_];
        FractionMath.Fraction memory interestMax = _maxInterestMin[token_];

        if (utilized.mul(utilization.denominator) > tvl(token_).mul(utilization.numerator))
            return _interestRateMax(valueLocked, utilized, utilization, interestMin, interestMax);
        else return (utilized.mul(interestMin.numerator), valueLocked.mul(interestMin.denominator));
    }

    // Get the interest on a given asset for a given number of blocks
    function interest(
        IERC20 token_,
        uint256 initialBorrow_,
        uint256 borrowBlock_
    ) external view returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(borrowBlock_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);
        uint256 precision = 12; // Precision is calculated as the log of the maximum expected number of blocks borrowed for
        return FractionMath.fracExp(initialBorrow_, blocksPerCompound.mul(interestRateDenominator).div(interestRateNumerator), blocksSinceBorrow, precision);
    }
}
