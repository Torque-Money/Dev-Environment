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

    function getPrologueTimes() public view override returns (uint256, uint256) {
        // Return the times of when the prologue is between
        uint256 periodId = currentPeriodId();
        uint256 prologueStart = periodId.mul(periodLength);
        uint256 prologueEnd = prologueStart.add(cooldownLength);
        return (prologueStart, prologueEnd);
    }

    function isPrologue() public view override returns (bool) {
        // Check if the prologue period of the specified period is present
        (uint256 prologueStart, uint256 prologueEnd) = getPrologueTimes();

        uint256 current = block.timestamp;
        return current >= prologueStart && current < prologueEnd;
    }

    function getEpilogueTimes() public view override returns (uint256, uint256) {
        // Return the times of when the epilogue is between
        uint256 periodId = currentPeriodId().add(1);
        uint256 epilogueEnd = periodId.mul(periodLength);
        uint256 epilogueStart = epilogueEnd.sub(cooldownLength);
        return (epilogueStart, epilogueEnd);
    }

    function isEpilogue() public view override returns (bool) {
        // Check if the epilogue period of the specified period is present
        (uint256 epilogueStart, uint256 epilogueEnd) = getEpilogueTimes();

        uint256 current = block.timestamp;
        return current >= epilogueStart && current < epilogueEnd;
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

    function getLiquidity(IERC20 _token) external view override approvedOnly(_token) returns (uint256) {
        return stakingPeriods[currentPeriodId()][_token].liquidity;
    }

    // ======== Balance management ========

    function balanceOf(address _account, IERC20 _token, uint256 _periodId) public view override approvedOnly(_token) returns (uint256) {
        // Get the amount of tokens the account deposited into a given period
        return stakingPeriods[_periodId][_token].deposits[_account];
    }

    function balanceOf(address _account, IERC20 _token) external view override approvedOnly(_token) returns (uint256) {
        // Get the amount of tokens the account deposited into the current period
        return balanceOf(_account, _token, currentPeriodId());
    }

    function redeemValue(IERC20 _token, uint256 _periodId, uint256 _amount) public view override approvedOnly(_token) returns (uint256) {
        // Get the value for redeeming a given amount of tokens for a given periodId
        StakingPeriod storage period = stakingPeriods[_periodId][_token];

        uint256 totalDeposited = period.totalDeposited;
        uint256 liquidity = period.liquidity;

        return _amount.mul(liquidity).div(totalDeposited);
    }

    // ======== Liquidity manipulation ========

    function stakeNext(IERC20 _token, uint256 _amount) external override approvedOnly(_token) {
        // Make sure they cant stake into the next period during a prologue
        require(!isPrologue(), "Cannot stake into the next period during the prologue phase of the current staking period");
        
        // Set the period ID as the next period id
        uint256 periodId = currentPeriodId().add(1);

        // Move the tokens to the pool and update the users deposit amount
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        // Update the balances
        StakingPeriod storage stakingPeriod = stakingPeriods[periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(_amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(_amount);

        emit Stake(_msgSender(), periodId, _token, _amount);
    }

    function stake(IERC20 _token, uint256 _amount) external override approvedOnly(_token) {
        // Make sure the requirements are satisfied
        require(isPrologue(), "Staking is only allowed during the prologue period");

        uint256 periodId = currentPeriodId();

        // Move the tokens to the pool and update the users deposit amount
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        StakingPeriod storage stakingPeriod = stakingPeriods[periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(_amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(_amount);

        emit Stake(_msgSender(), periodId, _token, _amount);
    }

    function restake(address _account, IERC20 _token, uint256 _periodId) public override approvedOnly(_token) {
        // Redeposit existing deposited amount from a previous period into the current period for a given user
        require(isPrologue(), "Restaking is only allowed during the prologue period");
        uint256 periodId = currentPeriodId();
        require(periodId != _periodId, "Cannot restake into the same period");

        StakingPeriod storage oldStakingPeriod = stakingPeriods[_periodId][_token];
        StakingPeriod storage stakingPeriod = stakingPeriods[periodId][_token];

        require(oldStakingPeriod.deposits[_account] > 0, "Nothing to restake from this period");

        // Remove the stake from the old period
        uint256 oldDeposit = oldStakingPeriod.deposits[_account];

        uint256 tokensRedeemed = redeemValue(_token, _periodId, oldDeposit);
        oldStakingPeriod.liquidity = oldStakingPeriod.liquidity.sub(tokensRedeemed);

        oldStakingPeriod.totalDeposited = oldStakingPeriod.totalDeposited.sub(oldDeposit);
        oldStakingPeriod.deposits[_account] = oldStakingPeriod.deposits[_account].sub(oldDeposit);

        // If the restake was not called by the user then issue a reward
        uint256 reward = 0;
        if (_account != _msgSender()) {
            reward = tokensRedeemed.mul(restakeReward).div(100);
            _token.safeTransfer(_msgSender(), reward);
        }

        // Update the new period
        uint256 newDeposit = tokensRedeemed.sub(reward);

        stakingPeriod.deposits[_account] = stakingPeriod.deposits[_account].add(newDeposit);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(newDeposit);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(newDeposit);

        emit Restake(_account, periodId, _token, _msgSender(), _periodId);
    }

    function restake(IERC20 _token, uint256 _periodId) external override {
        // Redeposit existing deposited amount from a previous period into the current period for the current user
        restake(_msgSender(), _token, _periodId);
    }

    function redeem(IERC20 _token, uint256 _amount, uint256 _periodId) external override approvedOnly(_token) {
        // Make sure the requirements are satisfied
        require(isPrologue() || !isCurrentPeriod(_periodId), "Withdraw is only allowed during prologue period or once period has ended");
        require(_amount <= balanceOf(_msgSender(), _token, _periodId), "Cannot redeem more than total balance");

        // Update the balances of the period
        StakingPeriod storage stakingPeriod = stakingPeriods[_periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].sub(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.sub(_amount);

        // Withdraw the allocated amount from the pool and return it to the user
        uint256 tokensRedeemed = redeemValue(_token, _periodId, _amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(tokensRedeemed);
        _token.safeTransfer(_msgSender(), tokensRedeemed);
        emit Redeem(_msgSender(), _periodId, _token, _amount, tokensRedeemed);
    }

    function deposit(IERC20 _token, uint256 _amount) external override approvedOnly(_token) {
        // Make sure no deposits during cooldown period
        require(!isPrologue(), "Cannot deposit during prologue");

        uint256 periodId = currentPeriodId();

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
        require(!isPrologue(), "Cannot withdraw during prologue");

        uint256 periodId = currentPeriodId();

        // Withdraw an amount from the current pool
        StakingPeriod storage stakingPeriod = stakingPeriods[periodId][_token]; 
        require(_amount <= stakingPeriod.liquidity, "Cannot withdraw more than value pool");
        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(_amount);
        _token.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), periodId, _token, _amount);
    }
}