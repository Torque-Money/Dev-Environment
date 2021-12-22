//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPool.sol";
import "./IYieldApproved.sol";

contract YieldApproved is Ownable, IYieldApproved {
    using SafeMath for uint256;

    LPool public immutable pool;

    mapping(uint256 => mapping(address => mapping(IERC20 => uint256))) private Yields; // Period id => account => token => stake

    constructor(LPool pool_) {
        pool = pool_; 
    }

    /** @dev Check if an account is eligible to earn a yield on a stake */
    function yieldApproved(address _account, IERC20 _token) external override returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        require(!pool.isPrologue(periodId), "Cannot approve yield during prologue phase");
        require(Yields[periodId][_account][_token] == 0, "Yield has already been approved");

        uint256 stake = pool.balanceOf(_account, _token, periodId);
        Yields[periodId][_account][_token] = stake;
        return stake;
    }
}