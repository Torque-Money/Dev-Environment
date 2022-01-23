//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "../lib/FractionMath.sol";
import "./LPoolLiquidity.sol";

import "hardhat/console.sol";

abstract contract LPoolInterest is LPoolLiquidity {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 public blocksPerInterestApplication;

    mapping(IERC20 => FractionMath.Fraction) private _maxInterestMin;
    mapping(IERC20 => FractionMath.Fraction) private _maxInterestMax;

    mapping(IERC20 => FractionMath.Fraction) private _maxUtilization;

    constructor(uint256 blocksPerInterestApplication_) {
        blocksPerInterestApplication = blocksPerInterestApplication_;
    }

    // Set the number of blocks the interest rate is calculated for
    function setBlocksPerInterestApplication(uint256 blocksPerInterestApplication_) external onlyRole(POOL_ADMIN) {
        blocksPerInterestApplication = blocksPerInterestApplication_;
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
            _maxInterestMin[token_[i]].numerator = percentNumerator_[i];
            _maxInterestMin[token_[i]].denominator = percentDenominator_[i];
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
            _maxInterestMax[token_[i]].numerator = percentNumerator_[i];
            _maxInterestMax[token_[i]].denominator = percentDenominator_[i];
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
            _maxUtilization[token_[i]].numerator = percentNumerator_[i];
            _maxUtilization[token_[i]].denominator = percentDenominator_[i];
        }
    }

    // Helper to calculate the minimum interest rate
    function _interestRateMin(
        uint256 utilizationNumerator_,
        uint256 utilizationDenominator_,
        FractionMath.Fraction memory interestMin_
    ) internal pure returns (uint256, uint256) {
        return (utilizationNumerator_.mul(interestMin_.numerator), utilizationDenominator_.mul(interestMin_.denominator));
    }

    // Helper to calculate the maximum interest rate
    function _interestRateMax(
        uint256 utilizationNumerator_,
        uint256 utilizationDenominator_,
        FractionMath.Fraction memory utilizationMax_,
        FractionMath.Fraction memory interestMin_,
        FractionMath.Fraction memory interestMax_
    ) internal pure returns (uint256, uint256) {
        int256 kNumerator;
        {
            kNumerator = interestMax_
                .numerator
                .toInt256()
                .add(interestMin_.denominator.toInt256())
                .sub(interestMin_.numerator.toInt256().mul(interestMax_.denominator.toInt256()))
                .mul(utilizationMax_.numerator.toInt256());
        }
        int256 kDenominator;
        {
            kDenominator = interestMax_.denominator.toInt256().mul(interestMin_.denominator.toInt256()).mul(utilizationMax_.denominator.toInt256());
        }

        int256 numerator;
        {
            numerator = utilizationNumerator_.toInt256().mul(interestMax_.numerator.toInt256()).mul(kDenominator).sub(
                kNumerator.mul(utilizationDenominator_.toInt256()).mul(interestMax_.denominator.toInt256())
            );
        }
        int256 denominator;
        {
            denominator = utilizationDenominator_.toInt256().mul(interestMax_.denominator.toInt256()).mul(kDenominator);
        }

        return (numerator.toUint256(), denominator.toUint256());
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 token_) public view override returns (uint256, uint256) {
        (uint256 utilizationNumerator, uint256 utilizationDenominator) = utilizationRate(token_);

        FractionMath.Fraction memory utilizationMax = _maxUtilization[token_];
        FractionMath.Fraction memory interestMin = _maxInterestMin[token_];
        FractionMath.Fraction memory interestMax = _maxInterestMin[token_];

        if (utilizationNumerator.mul(utilizationMax.denominator) > utilizationDenominator.mul(utilizationMax.numerator))
            return _interestRateMax(utilizationNumerator, utilizationDenominator, utilizationMax, interestMin, interestMax);
        else return _interestRateMin(utilizationNumerator, utilizationDenominator, interestMin);
    }

    // Get the accumulated interest on a given asset for a given number of blocks
    function interest(
        IERC20 token_,
        uint256 initialBorrow_,
        uint256 borrowBlock_
    ) external view returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(borrowBlock_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);

        return initialBorrow_.mul(interestRateNumerator).mul(blocksSinceBorrow).div(interestRateDenominator).div(blocksPerInterestApplication);
    }
}
