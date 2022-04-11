//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {FractionMath} from "../lib/FractionMath.sol";

import {LPoolLiquidity} from "./LPoolLiquidity.sol";

abstract contract LPoolInterest is Initializable, LPoolLiquidity {
    using SafeMathUpgradeable for uint256;
    using FractionMath for FractionMath.Fraction;

    uint256 public timePerInterestApplication;

    mapping(address => FractionMath.Fraction) private _maxInterestMin;
    mapping(address => FractionMath.Fraction) private _maxInterestMax;
    mapping(address => FractionMath.Fraction) private _maxUtilization;

    function initializeLPoolInterest(uint256 timePerInterestApplication_) public initializer {
        timePerInterestApplication = timePerInterestApplication_;
    }

    // Set the time the interest rate is applied after
    function setTimePerInterestApplication(uint256 timePerInterestApplication_) external onlyRole(POOL_ADMIN) {
        timePerInterestApplication = timePerInterestApplication_;
    }

    // Get the max interest for minimum utilization for the given token
    function maxInterestMin(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return _maxInterestMin[token_].export();
    }

    // Set the max interest for minimum utilization for the given token
    function setMaxInterestMin(
        address[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _maxInterestMin[token_[i]].numerator = percentNumerator_[i];
                _maxInterestMin[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the max interest for maximum utilization for the given token
    function maxInterestMax(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return _maxInterestMax[token_].export();
    }

    // Set the max interest for maximum utilization for the given token
    function setMaxInterestMax(
        address[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _maxInterestMax[token_[i]].numerator = percentNumerator_[i];
                _maxInterestMax[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Get the max utilization threshold for the given token
    function maxUtilization(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return _maxUtilization[token_].export();
    }

    // Set the max utilization threshold for the given token
    function setMaxUtilization(
        address[] memory token_,
        uint256[] memory percentNumerator_,
        uint256[] memory percentDenominator_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _maxUtilization[token_[i]].numerator = percentNumerator_[i];
                _maxUtilization[token_[i]].denominator = percentDenominator_[i];
            }
        }
    }

    // Helper to calculate the minimum interest rate
    function _interestRateMin(
        FractionMath.Fraction memory utilization_,
        FractionMath.Fraction memory utilizationMax_,
        FractionMath.Fraction memory interestMin_
    ) internal pure returns (FractionMath.Fraction memory) {
        return utilization_.mul(interestMin_).div(utilizationMax_);
    }

    // Helper to calculate the maximum interest rate
    function _interestRateMax(
        FractionMath.Fraction memory utilization_,
        FractionMath.Fraction memory interestMin_,
        FractionMath.Fraction memory utilizationMax_,
        FractionMath.Fraction memory interestMax_
    ) internal pure returns (FractionMath.Fraction memory) {
        FractionMath.Fraction memory slope = interestMax_.sub(interestMin_).div(FractionMath.create(1, 1).sub(utilizationMax_));

        return slope.mul(utilization_).add(interestMax_).sub(slope);
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(address token_) public view override onlyPT(token_) returns (uint256, uint256) {
        (uint256 utilizationNumerator, uint256 utilizationDenominator) = utilizationRate(token_);

        FractionMath.Fraction memory utilization = FractionMath.create(utilizationNumerator, utilizationDenominator);
        FractionMath.Fraction memory utilizationMax = _maxUtilization[token_];
        FractionMath.Fraction memory interestMin = _maxInterestMin[token_];
        FractionMath.Fraction memory interestMax = _maxInterestMax[token_];

        if (utilization.gt(utilizationMax)) return _interestRateMax(utilization, interestMin, utilizationMax, interestMax).export();
        else return _interestRateMin(utilization, utilizationMax, interestMin).export();
    }

    // Get the accumulated interest on a given asset for a given amount of time
    function interest(
        address token_,
        uint256 borrowPrice_,
        uint256 borrowTime_
    ) public view onlyPT(token_) returns (uint256) {
        uint256 timeSinceBorrow = block.timestamp.sub(borrowTime_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);

        return borrowPrice_.mul(interestRateNumerator).mul(timeSinceBorrow).div(interestRateDenominator).div(timePerInterestApplication);
    }
}
