//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LPoolApproved.sol";
import "./LPoolPeriod.sol";
import "./LPoolTax.sol";
import "./LPoolLiquidity.sol";

abstract contract LPoolAdmin is LPoolApproved, LPoolTax, LPoolLiquidity {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /** @dev Allow an approved user to claim liquidity as their own without removing liquidity from the pool */
    function claim(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot claim during prologue");
        require(_amount <= liquidity(_token, periodId), "Cannot claim more than available liquidity");

        StakingPeriod storage stakingPeriod = StakingPeriods[periodId][_token];

        stakingPeriod.totalClaimed = stakingPeriod.totalClaimed.add(_amount);
        stakingPeriod.claims[_msgSender()] = stakingPeriod.claims[_msgSender()].add(_amount);

        emit Claim(_msgSender(), periodId, _token, _amount);
    }

    /** @dev Allow an approved user to unclaim liquidity */
    function unclaim(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot unclaim during prologue");

        StakingPeriod storage stakingPeriod = StakingPeriods[periodId][_token];

        require(_amount <= stakingPeriod.claims[_msgSender()], "Cannot unclaim more than what you have claimed");

        stakingPeriod.totalClaimed = stakingPeriod.totalClaimed.sub(_amount);
        stakingPeriod.claims[_msgSender()] = stakingPeriod.claims[_msgSender()].sub(_amount);

        emit Unclaim(_msgSender(), periodId, _token, _amount);
    }

    /** @dev Deposit tokens into the pool and increase the liquidity of the pool */
    function deposit(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApproved(_token) {
        uint256 periodId = currentPeriodId();

        // Pay a tax to the contract owner
        uint256 amount = _amount;
        {
            uint256 tax = _amount.mul(taxPercent).div(100);
            amount = amount.sub(tax);
            _token.safeTransferFrom(_msgSender(), taxAccount, tax);
        }

        _token.safeTransferFrom(_msgSender(), address(this), amount);
        StakingPeriods[periodId][_token].liquidity = StakingPeriods[periodId][_token].liquidity.add(amount);

        emit Deposit(_msgSender(), periodId, _token, amount);
    }

    /** @dev Withdraw tokens from the pool and decrease the liquidity of the pool */
    function withdraw(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot withdraw during prologue");
        require(_amount <= liquidity(_token, periodId), "Cannot withdraw more than what is in pool");

        // Withdraw an amount from the current pool
        StakingPeriod storage stakingPeriod = StakingPeriods[periodId][_token]; 

        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(_amount);
        _token.safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), periodId, _token, _amount);
    }

    event Claim(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Unclaim(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
}