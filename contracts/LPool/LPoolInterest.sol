//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "../lib/FractionMath.sol";
import "./LPoolLiquidity.sol";

abstract contract LPoolInterest is Initializable, LPoolLiquidity {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 public blocksPerInterestApplication;

    mapping(IERC20 => FractionMath.Fraction) private _maxInterestMin;
    mapping(IERC20 => FractionMath.Fraction) private _maxInterestMax;
    mapping(IERC20 => FractionMath.Fraction) private _maxUtilization;

    function initialize(uint256 blocksPerInterestApplication_) external initializer {
        blocksPerInterestApplication = blocksPerInterestApplication_;
    }

    // Set the number of blocks the interest rate is calculated for
    function setBlocksPerInterestApplication(uint256 blocksPerInterestApplication_) external onlyRole(POOL_ADMIN) {
        blocksPerInterestApplication = blocksPerInterestApplication_;
    }

    // Get the max interest for minimum utilization for the given token
    function maxInterestMin(IERC20 token_) public view onlyPT(token_) returns (uint256, uint256) {
        return (_maxInterestMin[token_].numerator, _maxInterestMin[token_].denominator);
    }

    // Set the max interest for minimum utilization for the given token
    function setMaxInterestMin(
        IERC20[] memory token_,
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
    function maxInterestMax(IERC20 token_) public view onlyPT(token_) returns (uint256, uint256) {
        return (_maxInterestMax[token_].numerator, _maxInterestMax[token_].denominator);
    }

    // Set the max interest for maximum utilization for the given token
    function setMaxInterestMax(
        IERC20[] memory token_,
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
    function maxUtilization(IERC20 token_) public view onlyPT(token_) returns (uint256, uint256) {
        return (_maxUtilization[token_].numerator, _maxUtilization[token_].denominator);
    }

    // Set the max utilization threshold for the given token
    function setMaxUtilization(
        IERC20[] memory token_,
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
    function _interestRateMin(FractionMath.Fraction memory utilization_, FractionMath.Fraction memory interestMin_) internal pure returns (uint256, uint256) {
        return (utilization_.numerator.mul(interestMin_.numerator), utilization_.denominator.mul(interestMin_.denominator));
    }

    // Helper to calculate the maximum interest rate
    function _interestRateMax(
        FractionMath.Fraction memory utilization_,
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
            numerator = utilization_.numerator.toInt256().mul(interestMax_.numerator.toInt256()).mul(kDenominator).sub(
                kNumerator.mul(utilization_.denominator.toInt256()).mul(interestMax_.denominator.toInt256())
            );
        }
        int256 denominator;
        {
            denominator = utilization_.denominator.toInt256().mul(interestMax_.denominator.toInt256()).mul(kDenominator);
        }

        return (numerator.toUint256(), denominator.toUint256());
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 token_) public view override onlyPT(token_) returns (uint256, uint256) {
        (uint256 utilizationNumerator, uint256 utilizationDenominator) = utilizationRate(token_);
        FractionMath.Fraction memory utilization = FractionMath.Fraction({numerator: utilizationNumerator, denominator: utilizationDenominator});

        FractionMath.Fraction memory utilizationMax = _maxUtilization[token_];
        FractionMath.Fraction memory interestMin = _maxInterestMin[token_];
        FractionMath.Fraction memory interestMax = _maxInterestMin[token_];

        if (utilizationNumerator.mul(utilizationMax.denominator) > utilizationDenominator.mul(utilizationMax.numerator))
            return _interestRateMax(utilization, utilizationMax, interestMin, interestMax);
        else return _interestRateMin(utilization, interestMin);
    }

    // Get the accumulated interest on a given asset for a given number of blocks
    function interest(
        IERC20 token_,
        uint256 initialBorrow_,
        uint256 borrowBlock_
    ) public view onlyPT(token_) returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(borrowBlock_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);

        return initialBorrow_.mul(interestRateNumerator).mul(blocksSinceBorrow).div(interestRateDenominator).div(blocksPerInterestApplication);
    }
}
