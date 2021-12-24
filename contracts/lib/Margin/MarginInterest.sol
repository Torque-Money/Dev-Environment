//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginBorrowHelper.sol";

abstract contract MarginInterest is MarginBorrowHelper {
    using SafeMath for uint256;

    uint256 public maxInterestPercent;

    /** @dev Get the interest rate for a given asset per second
        interest = maxInterestRate * totalBorrowed / (totalBorrowed + liquidity) */
    function interestRate(IERC20 _token) public view returns (uint256) {
        uint256 utilization = utilizationRate(_token);
        return utilization.mul(maxInterestPercent).div(100).div(pool.periodLength());
    }

    /** @dev Calculate the interest at the current time for a given asset from the amount initially borrowed
        interest = maxInterestPercent * priceBorrowedInitially * interestRate * (timeBorrowed / interestPeriod) */
    function interest(IERC20 _borrowed, uint256 _initialBorrow, uint256 _borrowTime) public view returns (uint256) {
        uint256 retValue;
        { retValue = _initialBorrow.mul(interestRate(_borrowed)); }
        { retValue = retValue.mul(block.timestamp.sub(_borrowTime)).div(oracle.decimals()); }
        return retValue;
    }

    /** @dev Set the maximum interest percent */
    function setMaxInterestPercent(uint256 _maxInterestPercent) external onlyOwner {
        maxInterestPercent = _maxInterestPercent;
    }

    /** @dev Get the percentage of the pool of a given token being utilized by borrowers */
    function utilizationRate(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        uint256 _borrowed = borrowed(_token);
        uint256 _tvl = pool.tvl(_token, periodId);
        return _borrowed.mul(oracle.decimals()).div(_tvl);
    }
}