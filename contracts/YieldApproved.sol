//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VPool.sol";

contract YieldApproved is Ownable {
    using SafeMath for uint256;

    mapping(uint256 => mapping(address => bool)) private yields; // Track all of the approved yields to ensure no double payouts
    mapping(IERC20 => uint256) private minStake;

    VPool public pool;

    constructor(VPool pool_) {
        pool = pool_; 
    }

    modifier onlyApproved(IERC20 _token) {
        require(pool.isApproved(_token), "This token has not been approved");
        _;
    }

    function setMinStake(IERC20 _token, uint256 _amount) external onlyOwner onlyApproved {
        minStake[_token] = _amount;
    }

    function yieldApproved(address _account) external returns (bool) {
        // Get the period id
        uint256 periodId = pool.currentPeriodId();
        require(!yields[periodId][_account], "Yield has already been approved");
        require(!pool.isPrologue(periodId), "Cannot approve yield during prologue phase");

        // Check if the account has an asset staked that exceeds the amount needed for a reward to be paid out
        IERC20[] memory approved = pool.approvedList;
        for (uint256 i = 0; i < approved.length; i++) {
            IERC20 asset = approved[i];
            if (pool.balanceOf(_account, asset, periodId) >= minStake[_token]) {
                yields[periodId][_account] = true;
                return true;
            }
        }
        return false;
    }
}