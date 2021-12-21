//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPool.sol";
import "./IYieldApproved.sol";

contract YieldApproved is Ownable, IYieldApproved {
    using SafeMath for uint256;

    mapping(uint256 => mapping(address => bool)) private Yields;
    mapping(IERC20 => uint256) private MinStakes;

    LPool public immutable pool;

    constructor(LPool pool_) {
        pool = pool_; 
    }

    /** @dev Set the minimum stake of a given token required to earn a yield */
    function setMinStake(IERC20 _token, uint256 _amount) external onlyOwner {
        require(pool.isApproved(_token), "This token has not been approved");
        MinStakes[_token] = _amount;
    }

    /** @dev Check if an account is eligible to earn a yield on a stake */
    function yieldApproved(address _account) external override returns (bool) {
        uint256 periodId = pool.currentPeriodId();
        require(!Yields[periodId][_account], "Yield has already been approved");
        require(!pool.isPrologue(periodId), "Cannot approve yield during prologue phase");

        // Check if the account has an asset staked that exceeds the amount needed for a reward to be paid out
        IERC20[] memory approved = pool.approvedList();
        for (uint256 i = 0; i < approved.length; i++) {
            IERC20 asset = approved[i];
            if (pool.balanceOf(_account, asset, periodId) >= MinStakes[asset]) {
                Yields[periodId][_account] = true;
                return true;
            }
        }
        return false;
    }
}