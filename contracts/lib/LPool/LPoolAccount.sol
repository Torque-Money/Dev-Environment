//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LPoolApproved.sol";
import "./LPoolPeriod.sol";

abstract contract LPoolAccount is LPoolApproved, LPoolPeriod {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /** @dev Returns the deposited balance of a given account for a given token for a given period */
    function balanceOf(address _account, IERC20 _token, uint256 _periodId) public view returns (uint256) {
        return StakingPeriods[_periodId][_token].deposits[_account];
    }

    /** @dev Returns the value of the tokens for a given period for a given token once they are redeemed */
    function redeemValue(IERC20 _token, uint256 _amount, uint256 _periodId) public view onlyApproved(_token) returns (uint256) {
        StakingPeriod storage period = StakingPeriods[_periodId][_token];
        if (isPrologue(_periodId)) return _amount;
        return _amount.mul(period.liquidity).div(period.totalDeposited);
    }

    /** @dev Stakes a given amount of specified tokens in the pool */
    function stake(IERC20 _token, uint256 _amount, uint256 _periodId) external onlyApproved(_token) {
        require(isPrologue(_periodId) || _periodId > currentPeriodId(), "Staking is only allowed during the prologue period or for a future period");

        // Move the tokens to the pool and update the users deposit amount
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(_amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(_amount);

        emit Stake(_msgSender(), _periodId, _token, _amount);
    }

    /** @dev Redeems the staked amount of tokens in a given pool */
    function redeem(IERC20 _token, uint256 _amount, uint256 _periodId) external {
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Redeem is only allowed during prologue period or once period has ended");
        require(_amount <= balanceOf(_msgSender(), _token, _periodId), "Cannot redeem more than total balance");

        // Update the balances of the period, withdraw collateral and return to user
        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];

        uint256 tokensRedeemed = redeemValue(_token, _amount, _periodId);

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].sub(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.sub(_amount);

        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(tokensRedeemed);
        _token.safeTransfer(_msgSender(), tokensRedeemed);

        emit Redeem(_msgSender(), _periodId, _token, _amount, tokensRedeemed);
    }

    event Stake(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Redeem(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount, uint256 liquidity);
}