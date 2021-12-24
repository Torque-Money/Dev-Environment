//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Oracle.sol";
import "./LPool.sol";
import "./lib/UniswapV2Router02.sol";
import "./lib/MarginCore.sol";

contract Margin is Ownable, MarginCore {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private BorrowPeriods;

    constructor(Oracle oracle_, LPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_)
        MarginCore(oracle_, pool_, minBorrowLength_, maxInterestPercent_, minMarginThreshold_)
    {}

    // ======== Getters ========

    /** @dev Return the total amount of a given asset borrowed */
    function borrowed(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        return BorrowPeriods[periodId][_token].totalBorrowed;
    }

    /** @dev Get the margin level of the given account */
    function marginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (uint256) {
        BorrowAccount storage borrowAccount = BorrowPeriods[pool.currentPeriodId()][_borrowed].collateral[_account][_collateral];
        uint256 interest = calculateInterest(_borrowed, borrowAccount.initialPrice, borrowAccount.initialBorrowTime);
        return _marginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.borrowed, _collateral, _borrowed, interest);
    }

    /** @dev Get the percentage of the pool of a given token being utilized by borrowers */
    function utilizationRate(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        uint256 _borrowed = borrowed(_token);
        uint256 _tvl = pool.tvl(_token, periodId);
        return _borrowed.mul(oracle.decimals()).div(_tvl);
    }


    // ======== Deposit and withdraw ========


    // ======== Borrow ========

    /** @dev Get the most recent borrow time for a given account */
    function borrowTime(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.borrowTime;
    }

    /** @dev Get the initial borrow time of the account */
    function initialBorrowTime(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.initialBorrowTime;
    }

    // **** I think I would like a number of the total collateral borrowed too just to be difficult

    // ======== Repay and withdraw ========

    // ======== Liquidate ========


    // ======== Events ========
}