//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPool.sol";
import "./Margin.sol";
import "./IYield.sol";

contract YieldApproved is Ownable, IYieldApproved {
    using SafeMath for uint256;

    LPool public immutable pool;
    Margin public immutable margin;

    struct Yield {
        uint256 stake;
        uint256 borrow;
    }
    mapping(uint256 => mapping(address => mapping(IERC20 => Yield))) private Yields; // Period id => account => token => stake

    constructor(LPool pool_, Margin margin_) {
        pool = pool_; 
        margin = margin_;
    }

    /** @dev Check if an account is eligible to earn a yield on a stake / borrow and return the amount */
    function yieldApproved(address _account, IERC20 _token) external override returns (uint256, uint256) {
        uint256 periodId = pool.currentPeriodId();
        require(!pool.isPrologue(periodId), "Cannot approve yield during prologue phase");
        Yield storage yield = Yields[periodId][_account][_token];
        require(yield.stake == 0 || yield.borrow == 0, "Yield has already been approved");

        uint256 stake = 0;
        if (yield.stake == 0) {
            stake = pool.balanceOf(_account, _token, periodId);
            Yields[periodId][_account][_token].stake = stake;
        }

        uint256 borrow = 0;
        if (yield.borrow == 0) {
            IERC20[] memory tokens = pool.approvedList();
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 borrowed = margin.debtOf(_account, tokens[i], _token);
                if (borrowed > borrow) borrow = borrowed;
            }
        }

        return (stake, borrow);
    }
}