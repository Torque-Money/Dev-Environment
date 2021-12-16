//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IVPool.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VPool is IVPool, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Approved assets of the pool
    IERC20[] private approvedList;
    mapping(IERC20 => bool) private approved;

    // Staking data
    struct StakingPeriod {
        uint256 totalDeposited;
        uint256 liquidity;
        mapping(address => uint256) deposits;
    }
    mapping(uint256 => mapping(IERC20 => StakingPeriod)) private stakingPeriods; // Stores the data for each approved asset
    uint256 private periodLength;
    uint256 private cooldownLength;

    uint256 private restakeReward; // Percentage of amount restaked

    address private taxAccount;
    uint256 private taxPercent;

    constructor(uint256 periodLength_, uint256 cooldownLength_, uint256 restakeReward_, uint256 taxPercent_) {
        periodLength = periodLength_;
        cooldownLength = cooldownLength_;
        restakeReward = restakeReward_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        taxPercent = taxPercent_;
    }

    // ======== Tax payouts ========

    function setTaxAccount(address _taxAccount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        taxAccount = _taxAccount;
        emit TaxAccountChange(_taxAccount);
    }

    // ======== Check the staking period and cooldown periods ========

    function getPeriodLength() external view override returns (uint256) {
        return periodLength;
    }

    function getCooldownLength() external view override returns (uint256) {
        return cooldownLength;
    }

    function getPrologueTimes(uint256 _periodId) public view override returns (uint256, uint256) {
        // Return the times of when the prologue is between
        uint256 prologueStart = _periodId.mul(periodLength);
        uint256 prologueEnd = prologueStart.add(cooldownLength);
        return (prologueStart, prologueEnd);
    }

    function isPrologue(uint256 _periodId) public view override returns (bool) {
        // Check if the prologue period of the specified period is present
        (uint256 prologueStart, uint256 prologueEnd) = getPrologueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= prologueStart && current < prologueEnd);
    }

    function getEpilogueTimes(uint256 _periodId) public view override returns (uint256, uint256) {
        // Return the times of when the epilogue is between
        uint256 periodId = _periodId.add(1);
        uint256 epilogueEnd = periodId.mul(periodLength);
        uint256 epilogueStart = epilogueEnd.sub(cooldownLength);
        return (epilogueStart, epilogueEnd);
    }

    function isEpilogue(uint256 _periodId) public view override returns (bool) {
        // Check if the epilogue period of the specified period is present
        (uint256 epilogueStart, uint256 epilogueEnd) = getEpilogueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= epilogueStart && current < epilogueEnd);
    }

    function isCurrentPeriod(uint256 _periodId) public view override returns (bool) {
        return _periodId == currentPeriodId();
    }

    function currentPeriodId() public view override returns (uint256) {
        return uint256(block.timestamp).div(periodLength);
    }

    // ======== Approved tokens ========

    function approveToken(IERC20 _token) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        // Satisfy the requirements
        require(!isApproved(_token), "This token has already been approved");

        // Approve the token
        approved[_token] = true;
        approvedList.push(_token);
    }

    function isApproved(IERC20 _token) public view override returns (bool) {
        return approved[_token];
    }

    function getApproved() external view override returns (IERC20[] memory) {
        return approvedList;
    }

    modifier approvedOnly(IERC20 _token) {
        require(isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Helper functions ========

    function getLiquidity(IERC20 _token, uint256 _periodId) external view override approvedOnly(_token) returns (uint256) {
        return stakingPeriods[_periodId][_token].liquidity;
    }

    // ======== Balance management ========

    function balanceOf(address _account, IERC20 _token, uint256 _periodId) public view override approvedOnly(_token) returns (uint256) {
        // Get the amount of tokens the account deposited into a given period
        return stakingPeriods[_periodId][_token].deposits[_account];
    }

    function redeemValue(IERC20 _token, uint256 _amount, uint256 _periodId) public view override approvedOnly(_token) returns (uint256) {
        // Get the value for redeeming a given amount of tokens for a given periodId
        StakingPeriod storage period = stakingPeriods[_periodId][_token];

        uint256 totalDeposited = period.totalDeposited;
        uint256 liquidity = period.liquidity;

        return _amount.mul(liquidity).div(totalDeposited);
    }

    // ======== Liquidity manipulation ========

    function stake(IERC20 _token, uint256 _amount, uint256 _periodId) external override approvedOnly(_token) {
        // Make sure the requirements are satisfied
        require(_periodId >= currentPeriodId(), "May only stake into current or future periods");
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Staking is only allowed during the prologue period or for a future period");

        // Move the tokens to the pool and update the users deposit amount
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        StakingPeriod storage stakingPeriod = stakingPeriods[_periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(_amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(_amount);

        emit Stake(_msgSender(), _periodId, _token, _amount);
    }

    function restake(IERC20 _token, uint256 _periodIdFrom, uint256 _periodIdTo) external override approvedOnly(_token) {
        // Redeposit existing deposited amount from a previous period into the current period for a given user
        require(_periodIdFrom != _periodIdTo, "Cannot restake into the same period");
        require(_periodIdTo >= currentPeriodId(), "Can only restake into the current or future period");
        require((isPrologue(_periodIdFrom) || !isCurrentPeriod(_periodIdFrom)) && (isPrologue(_periodIdTo) || !isCurrentPeriod(_periodIdTo)), "Restaking is only allowed during the prologue period");

        StakingPeriod storage oldStakingPeriod = stakingPeriods[_periodIdFrom][_token];
        StakingPeriod storage stakingPeriod = stakingPeriods[_periodIdTo][_token];

        require(oldStakingPeriod.deposits[_msgSender()] > 0, "Nothing to restake from this period");

        // Remove the stake from the old period
        uint256 oldDeposit = oldStakingPeriod.deposits[_msgSender()];

        uint256 tokensRedeemed = redeemValue(_token, oldDeposit, _periodIdFrom);
        oldStakingPeriod.liquidity = oldStakingPeriod.liquidity.sub(tokensRedeemed);

        oldStakingPeriod.totalDeposited = oldStakingPeriod.totalDeposited.sub(oldDeposit);
        oldStakingPeriod.deposits[_msgSender()] = oldStakingPeriod.deposits[_msgSender()].sub(oldDeposit);

        // Update the new period
        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(tokensRedeemed);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(tokensRedeemed);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(tokensRedeemed);

        emit Restake(_msgSender(), _periodIdFrom, _token, _msgSender(), _periodIdTo);
    }

    function redeem(IERC20 _token, uint256 _amount, uint256 _periodId) external override approvedOnly(_token) {
        // Make sure the requirements are satisfied
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Withdraw is only allowed during prologue period or once period has ended");
        require(_amount <= balanceOf(_msgSender(), _token, _periodId), "Cannot redeem more than total balance");

        // Update the balances of the period
        StakingPeriod storage stakingPeriod = stakingPeriods[_periodId][_token];

        // Withdraw the allocated amount from the pool and return it to the user
        uint256 tokensRedeemed = redeemValue(_token, _amount, _periodId);

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].sub(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.sub(_amount);

        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(tokensRedeemed);
        _token.safeTransfer(_msgSender(), tokensRedeemed);

        emit Redeem(_msgSender(), _periodId, _token, _amount, tokensRedeemed);
    }

    function deposit(IERC20 _token, uint256 _amount) external override approvedOnly(_token) {
        // Make sure no deposits during cooldown period
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot deposit during prologue");

        // Pay a tax to the tax account
        uint256 amount = _amount;
        if (taxAccount != address(0)) {
            uint256 tax = _amount.mul(taxPercent).div(100);
            amount = amount.sub(tax);
            _token.safeTransferFrom(_msgSender(), address(this), tax);
        }

        // Receive a given number of funds to the current pool
        _token.safeTransferFrom(_msgSender(), address(this), amount);
        stakingPeriods[periodId][_token].liquidity = stakingPeriods[periodId][_token].liquidity.add(amount);
        emit Deposit(_msgSender(), periodId, _token, amount);
    }

    function withdraw(IERC20 _token, uint256 _amount) external override approvedOnly(_token) onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure no withdraws during cooldown period
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot withdraw during prologue");

        // Withdraw an amount from the current pool
        StakingPeriod storage stakingPeriod = stakingPeriods[periodId][_token]; 
        require(_amount <= stakingPeriod.liquidity, "Cannot withdraw more than value pool");
        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(_amount);
        _token.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), periodId, _token, _amount);
    }
}