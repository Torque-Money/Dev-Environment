//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginCore.sol";

abstract contract IsoMarginInterest is IsoMarginCore {
    using SafeMath for uint256;

    uint256 public maxInterestRate;

    constructor(uint256 maxInterestRate_) {
        maxInterestRate = maxInterestRate_;
    }

    // Set the max interest rate
    function setMaxInterestRate(uint256 _maxInterestRate) external onlyOwner {
        maxInterestRate = _maxInterestRate;
    }

    // Calculate the interest rate on a per block basis - returns numerator and denominator
    function interestRate(IERC20 _token) public view onlyApprovedToken(_token) returns (uint256, uint256) {
        // **** This should be calculated per block
    }
}