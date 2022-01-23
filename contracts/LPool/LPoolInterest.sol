//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";
import "./LPoolLiquidity.sol";

import "hardhat/console.sol";

abstract contract LPoolInterest is LPoolLiquidity {
    using SafeMath for uint256;

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
    ) internal view returns (uint256, uint256) {
        console.log("Made it here TOP");
        uint256 kNumerator;
        {
            kNumerator = interestMax_.numerator.add(interestMin_.denominator).sub(interestMin_.numerator.mul(interestMax_.denominator)).mul(utilizationMax_.numerator);
        }
        console.log("Made it here BOT");
        uint256 kDenominator;
        {
            kDenominator = interestMax_.denominator.mul(interestMin_.denominator).mul(utilizationMax_.denominator);
        }

        uint256 numerator;
        {
            numerator = utilizationNumerator_.mul(interestMax_.numerator).mul(kDenominator).sub(kNumerator.mul(utilizationDenominator_).mul(interestMax_.denominator));
        }
        uint256 denominator;
        {
            denominator = utilizationDenominator_.mul(interestMax_.denominator).mul(kDenominator);
        }

        return (numerator, denominator);
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
