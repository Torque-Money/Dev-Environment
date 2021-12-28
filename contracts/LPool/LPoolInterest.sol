//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolManipulation.sol";

abstract contract LPoolInterest is LPoolManipulation {
    uint256 public maxInterestMin;
    uint256 public maxInterestMax;

    uint256 public maxUtilization;

    constructor(uint256 maxInterestMin_, uint256 maxInterestMax_, uint256 maxUtilization_) {
        maxInterestMin = maxInterestMin_;
        maxInterestMax = maxInterestMax_;
        maxUtilization = maxUtilization_;
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

    // Get the interest rate for a given asset
    function interestRate(IERC20 _token) public view returns (uint256, uint256) {
        
    }
}