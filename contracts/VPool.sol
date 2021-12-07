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
        mapping(address => uint256) poolValue;
        mapping(address => mapping(address => uint256)) deposits;
    }
    mapping(uint256 => mapping(address => StakingPeriod)) private stakingPeriods; // Stores the data for each approved asset
    uint256 private stakingTimeframe;
    uint256 private cooldownTimeframe;

    constructor(uint256 stakingTimeframe_, uint256 cooldownTimeframe_) {
        stakingTimeframe = stakingTimeframe_;
        cooldownTimeframe = cooldownTimeframe_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function isCooldown() public {
        // We will look at if we are at the start of the given staking period based on the cooldown time, and if we are then we will exit
    }

    function currentStakingId() public view returns (uint256) {
        return uint256(block.timestamp).div(stakingTimeframe);
    }

    function stake() external returns (uint256) {
        // **** Can only stake during periods where it is valid to stake and is within the cooldown period (how will I do this using some clever maths ?)
        // **** Maybe I can do it if the current timeframe is the same number returned by the cooldown, but the timeframe will consider the entire timeframe a bit more ???
    }

    function balance(uint256 _periodId) external returns (uint256) {
        // Returns the total amount owed by the pool back to the user
    }

    function withdraw() external returns (uint256) {
        // **** This will only be possible to do during the cooldown period or after the thing has commenced
        // **** I will manually have to track the amount available to be used during the given period
        // **** Stakers will ONLY be able to withdraw the amount that has been tracked by the deposited itself. If that value in the StakingPeriod is not updated, it will not be possible
    }

    function lend() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // **** This will lend money out to another pool, and will also accumulate debt for the given pool
        // **** Lending can only be done via 
        // **** We are not lending out of the pool directly, we are lending off of the amount that was allocated to the stake
    }

    function repay() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // **** This will be used for redepositing tokens back into the staking pool
    }
}