//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FracExp.sol";
import "./LPoolManipulation.sol";

abstract contract LPoolInterest is LPoolManipulation {
    using SafeMath for uint256;

    uint256 public maxInterestMin;
    uint256 public maxInterestMax;

    uint256 public maxUtilization;

    uint256 public blocksPerCompound;

    constructor(uint256 maxInterestMin_, uint256 maxInterestMax_, uint256 maxUtilization_, uint256 blocksPerCompound_) {
        maxInterestMin = maxInterestMin_;
        maxInterestMax = maxInterestMax_;
        maxUtilization = maxUtilization_;
        blocksPerCompound = blocksPerCompound_;
    }

    // Set the max interest for minimum utilization
    function setMaxInterestMin(uint256 _maxInterestMin) external onlyRole(POOL_ADMIN) {
        maxInterestMin = _maxInterestMin;
    }

    // Set the max interest for maximum utilization
    function setMaxInterestMax(uint256 _maxInterestMax) external onlyRole(POOL_ADMIN) {
        maxInterestMax = _maxInterestMax;
    }

    // Set the max utilization threshold
    function setMaxUtilization(uint256 _maxUtilization) external onlyRole(POOL_ADMIN) {
        maxUtilization = _maxUtilization;
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 _token) public view returns (uint256, uint256) {
        uint256 valueLocked = tvl(_token);
        uint256 utilized = valueLocked.sub(liquidity(_token));

        uint256 maxInterest;
        if (utilized > maxUtilization) maxInterest = maxInterestMax;
        else maxInterest = maxInterestMin;

        return (utilized.mul(maxInterest), valueLocked); // Numerator and denominator of ratio
    }

    // Get the interest on a given asset for a given number of blocks
    function interest(IERC20 _token, uint256 _initialBorrow, uint256 _borrowBlock) external view returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(_borrowBlock);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(_token);
        uint256 precision = 12; // Precision is calculated as the log of the maximum expected number of blocks borrowed for
        return FracExp.fracExp(_initialBorrow, blocksPerCompound.mul(interestRateDenominator).div(interestRateNumerator), blocksSinceBorrow, precision);
    }
}