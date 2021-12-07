//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IVPool.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// **** For the moment users will have to withraw profits and restake into a new pool manually
// **** Perhaps in the future we will allow minting of a new token that will be used by the DAO - a specific amount of tokens based on supply will be allocated to each pool, and will be distributed out at the end

contract VPool is IVPool, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Approved assets of the pool
    address[] private approvedList;
    mapping(address => bool) private approved;

    // Staking data
    struct StakingPeriod {
        uint256 totalDeposited;
        uint256 liquidity;
        uint256 loaned;
        mapping(address => uint256) deposits;
    }
    mapping(uint256 => mapping(address => StakingPeriod)) private stakingPeriods; // Stores the data for each approved asset
    uint256 private stakingTimeframe;
    uint256 private cooldownTimeframe;

    constructor(uint256 stakingTimeframe_, uint256 cooldownTimeframe_) {
        stakingTimeframe = stakingTimeframe_;
        cooldownTimeframe = cooldownTimeframe_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // ======== Check the staking period and cooldown periods ========

    function isCooldown(uint256 _periodId) public view returns (bool) {
        // Check if the cooldown period of the specified period is present
        uint256 periodStart = _periodId.mul(stakingTimeframe);
        uint256 cooldownEnd = periodStart + cooldownTimeframe;
        uint256 current = block.timestamp;
        return current >= periodStart && current < cooldownEnd;
    }

    function isCooldown() public view returns (bool) {
        // Check if the cooldown period of the current period is present
        return isCooldown(currentPeriodId());
    }

    function isCurrentPeriod(uint256 _periodId) public view returns (bool) {
        return _periodId == currentPeriodId();
    }

    function currentPeriodId() public view returns (uint256) {
        return uint256(block.timestamp).div(stakingTimeframe);
    }

    // ======== Approved tokens ========

    function approveToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Satisfy the requirements
        require(!isApproved(_token), "This token has already been approved");

        // Approve the token
        approved[_token] = true;
        approvedList.push(_token);
    }

    function isApproved(address _token) public view returns (bool) {
        return approved[_token];
    }

    function getApproved() public view returns (address[] memory) {
        return approvedList;
    }

    modifier approvedOnly(address _token) {
        require(isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Balance management ========

    function balance(address _token, uint256 _periodId) public view approvedOnly(_token) returns (uint256) {
        // Get the amount of tokens the user deposited into a given period
        return stakingPeriods[_periodId][_token].deposits[_msgSender()];
    }

    function balance(address _token) external view approvedOnly(_token) returns (uint256) {
        // Get the amount of tokens the user deposited into the current period
        return balance(_token, currentPeriodId());
    }

    function redeemValue(address _token, uint256 _periodId, uint256 _amount) public view approvedOnly(_token) returns (uint256) {
        // Get the value for redeeming a given amount of tokens for a given periodId
        StakingPeriod storage period = stakingPeriods[_periodId][_token];

        uint256 totalDeposited = period.totalDeposited;
        uint256 liquidity = period.liquidity;
        uint256 loaned = period.loaned;

        return _amount.mul(liquidity.add(loaned)).div(totalDeposited);
    }

    // ======== Liquidity manipulation ========

    function deposit(address _token, uint256 _amount) external approvedOnly(_token) {
        // Make sure the requirements are satisfied
        require(isCooldown() == true, "Staking is only allowed during the cooldown period");

        // Move the tokens to the pool and update the users deposit amount
        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);

        uint256 periodId = currentPeriodId();
        stakingPeriods[periodId][_token].deposits[_msgSender()] = stakingPeriods[periodId][_token].deposits[_msgSender()].add(_amount);
        stakingPeriods[periodId][_token].liquidity = stakingPeriods[periodId][_token].liquidity.add(_amount);
        stakingPeriods[periodId][_token].totalDeposited = stakingPeriods[periodId][_token].totalDeposited.add(_amount);

        emit Deposit(_msgSender(), _token, periodId, _amount);
    }

    function redeem(address _token, uint256 _amount, uint256 _periodId) external approvedOnly(_token) returns (uint256) {
        // Make sure the requirements are satisfied
        require(isCooldown(_periodId) || !isCurrentPeriod(_periodId), "Withdraw is only allowed during cooldown or once period has ended");
        require(_amount <= balance(_token, _periodId), "Cannot redeem more than total balance");

        // **** OH NO - WHAT DO I DO IN THE CASE OF EVERYTHING BEING IN DEBT ??????? - THIS WOULDNT WORK IN THIS CASE BECAUSE IT MIGHT BE ALL IN DEBT EVEN THOUGH ITS STILL IN THE POOL ?????
        // **** Hangon, but this can only occur when there si nothing being borrowed, and therefore there would be no debt - I should remove the debt concept as a whole from this and put it in the margin
        // **** Hangon too, we are not changing the amount deposited OR the liquidity at this stage - that stays the same as what it was originally. All that should change is the percent remaining

        // Update the balances of the period
        uint256 totalDeposited = stakingPeriods[_periodId][_token].totalDeposited;
        uint256 deposit = stakingPeriods[_periodId][_token].deposits[_msgSender()];

        stakingPeriods[_periodId][_token].deposits[_msgSender()] = stakingPeriods[_periodId][_token].deposits[_msgSender()].sub(_amount);
        stakingPeriods[_periodId][_token].totalDeposited = stakingPeriods[_periodId][_token].totalDeposited.sub(_amount);
        stakingPeriods[_periodId][_token].liquidity = stakingPeriods[_periodId][_token].liquidity.sub(_amount);

        // Withdraw the allocated amount from the pool and return it to the user
        uint256 redeemed = 
    }

    function lend() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // **** This will lend money out to another pool, and will also accumulate debt for the given pool
        // **** Lending can only be done via 
        // **** We are not lending out of the pool directly, we are lending off of the amount that was allocated to the stake
    }

    function reportLost() external onlyRole(DEFAULT_ADMIN_ROLE) {

    }

    function repay() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // **** This will be used for redepositing tokens back into the staking pool
    }

    // ======== Events ========
    event Deposit(address indexed sender, address indexed token, uint256 indexed periodId, uint256 amount);
    event Redeem(address indexed sender, address indexed token, uint256 indexed periodId, uint256 amount);
}