//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./LPoolManipulation.sol";

abstract contract LPoolInterest is LPoolManipulation {
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
    function setMaxInterestMin(IERC20[] memory token_, uint256[] memory percentNumerator_, uint256[] memory percentDenominator_) external onlyRole(POOL_ADMIN) {
        for (uint i = 0; i < token_.length; i++) {
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
    function setMaxInterestMax(IERC20[] memory token_, uint256[] memory percentNumerator_, uint256[] memory percentDenominator_) external onlyRole(POOL_ADMIN) {
        for (uint i = 0; i < token_.length; i++) {
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
    function setMaxUtilization(IERC20[] memory token_, uint256[] memory percentNumerator_, uint256[] memory percentDenominator_) external onlyRole(POOL_ADMIN) {
        for (uint i = 0; i < token_.length; i++) {
            if (isPA(token_[i])) {
                _maxUtilization[token_[i]].numerator = percentNumerator_[i];
                _maxUtilization[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 token_) public view returns (uint256, uint256) {
        uint256 valueLocked = tvl(token_);
        uint256 utilized = valueLocked.sub(liquidity(token_));

        (uint256 maxUtilizationNumerator, uint256 maxUtilizationDenominator) = maxUtilization(token_);

        uint256 maxInterestNumerator;
        uint256 maxInterestDenominator;

        if (utilized > tvl(token_).mul(maxUtilizationNumerator).div(maxUtilizationDenominator)) (maxInterestNumerator, maxInterestDenominator) = maxInterestMax(token_);
        else (maxInterestNumerator, maxInterestDenominator) = maxInterestMin(token_);

        return (utilized.mul(maxInterestNumerator), valueLocked.mul(maxInterestDenominator));
    }

    // Get the interest on a given asset for a given number of blocks
    function interest(IERC20 token_, uint256 initialBorrow_, uint256 borrowBlock_) external view returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(borrowBlock_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);
        uint256 precision = 12; // Precision is calculated as the log of the maximum expected number of blocks borrowed for
        return FractionMath.fracExp(initialBorrow_, blocksPerCompound.mul(interestRateDenominator).div(interestRateNumerator), blocksSinceBorrow, precision);
    }
}