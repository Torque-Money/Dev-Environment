//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FracExp.sol";
import "./LPoolManipulation.sol";

abstract contract LPoolInterest is LPoolManipulation {
    using SafeMath for uint256;

    uint256 public blocksPerCompound;

    mapping(IERC20 => uint256) private _maxInterestMin;
    mapping(IERC20 => uint256) private _maxInterestMax;

    mapping(IERC20 => uint256) private _maxUtilization;

    constructor(uint256 blocksPerCompound_) {
        blocksPerCompound = blocksPerCompound_;
    }

    // Get the max interest for minimum utilization for the given token
   function maxInterestMin(IERC20 token_) public view returns (uint256) {
       return _maxInterestMin[token_];
   }

    // Set the max interest for minimum utilization for the given token
    function setMaxInterestMin(IERC20 token_, uint256 percent_) external onlyRole(POOL_ADMIN) {
        _maxInterestMin[token_] = percent_;
    }

    // Get the max interest for maximum utilization for the given token
    function maxInterestMax(IERC20 token_) public view returns (uint256) {
        return _maxInterestMax[token_];
    }

    // Set the max interest for maximum utilization for the given token
    function setMaxInterestMax(IERC20 token_, uint256 percent_) external onlyRole(POOL_ADMIN) {
        _maxInterestMax[token_] = percent_;
    }

    // Get the max utilization threshold for the given token
    function maxUtilization(IERC20 token_) public view returns (uint256) {
        return _maxUtilization[token_];
    }

    // Set the max utilization threshold for the given token
    function setMaxUtilization(IERC20 token_, uint256 percent_) external onlyRole(POOL_ADMIN) {
        _maxUtilization[token_] = percent_;
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 token_) public view returns (uint256, uint256) {
        uint256 valueLocked = tvl(token_);
        uint256 utilized = valueLocked.sub(liquidity(token_));

        uint256 maxInterest;
        if (utilized > maxUtilization(token_)) maxInterest = maxInterestMax(token_);
        else maxInterest = maxInterestMin(token_);

        return (utilized.mul(maxInterest), valueLocked.mul(100)); // Numerator and denominator of ratio
    }

    // Get the interest on a given asset for a given number of blocks
    function interest(IERC20 token_, uint256 initialBorrow_, uint256 borrowBlock_) external view returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(borrowBlock_);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(token_);
        uint256 precision = 12; // Precision is calculated as the log of the maximum expected number of blocks borrowed for
        return FracExp.fracExp(initialBorrow_, blocksPerCompound.mul(interestRateDenominator).div(interestRateNumerator), blocksSinceBorrow, precision);
    }
}