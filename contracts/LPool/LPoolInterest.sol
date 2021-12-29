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
   function maxInterestMin(IERC20 _token) public view returns (uint256) {
       return _maxInterestMin[_token];
   }

    // Set the max interest for minimum utilization for the given token
    function setMaxInterestMin(IERC20 _token, uint256 _percent) external onlyRole(POOL_ADMIN) {
        _maxInterestMin[_token] = _percent;
    }

    // Get the max interest for maximum utilization for the given token
    function maxInterestMax(IERC20 _token) public view returns (uint256) {
        return _maxInterestMax[_token];
    }

    // Set the max interest for maximum utilization for the given token
    function setMaxInterestMax(IERC20 _token, uint256 _percent) external onlyRole(POOL_ADMIN) {
        _maxInterestMax[_token] = _percent;
    }

    // Get the max utilization threshold for the given token
    function maxUtilization(IERC20 _token) public view returns (uint256) {
        return _maxUtilization[_token];
    }

    // Set the max utilization threshold for the given token
    function setMaxUtilization(IERC20 _token, uint256 _percent) external onlyRole(POOL_ADMIN) {
        _maxUtilization[_token] = _percent;
    }

    // Get the interest rate (in terms of numerator and denominator of ratio) for a given asset per compound
    function interestRate(IERC20 _token) public view returns (uint256, uint256) {
        uint256 valueLocked = tvl(_token);
        uint256 utilized = valueLocked.sub(liquidity(_token));

        uint256 maxInterest;
        if (utilized > maxUtilization(_token)) maxInterest = maxInterestMax(_token);
        else maxInterest = maxInterestMin(_token);

        return (utilized.mul(maxInterest), valueLocked.mul(100)); // Numerator and denominator of ratio
    }

    // Get the interest on a given asset for a given number of blocks
    function interest(IERC20 _token, uint256 _initialBorrow, uint256 _borrowBlock) external view returns (uint256) {
        uint256 blocksSinceBorrow = block.number.sub(_borrowBlock);
        (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(_token);
        uint256 precision = 12; // Precision is calculated as the log of the maximum expected number of blocks borrowed for
        return FracExp.fracExp(_initialBorrow, blocksPerCompound.mul(interestRateDenominator).div(interestRateNumerator), blocksSinceBorrow, precision);
    }
}