//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IVPool.sol";

// **** For the moment users will have to withraw profits and restake into a new pool manually

contract VPool is IVPool {
    struct StakingPeriod {
        uint256 totalDeposited;
    }
    mapping(uint256 => StakingPeriod) private stakingPeriods;
    uint256 private stakingTimeframe;
    uint256 private cooldownTimeframe;

    constructor(uint256 stakingTimeframe_, uint256 cooldownTimeframe_) {
        stakingTimeframe = stakingTimeframe_;
        cooldownTimeframe = cooldownTimeframe_;
    }

    function stake() external returns (uint256) {
        // **** Can only stake during periods where it is valid to stake and is within the cooldown period (how will I do this using some clever maths ?)
        // **** Maybe I can do it if the current timeframe is the same number returned by the cooldown, but the timeframe will consider the entire timeframe a bit more ???
    }

    function balance(uint256 _periodId) external returns (uint256) {

    }

    function withdraw() external returns (uint256) {
        // **** This will only be possible to do during the cooldown period or after the thing has commenced
        // **** I will manually have to track the amount available to be used during the given period
        // **** Stakers will ONLY be able to withdraw the amount that has been tracked by the deposited itself. If that value in the StakingPeriod is not updated, it will not be possible
    }

    function lend() external {
        // **** This will lend money out to another pool, and will also accumulate debt for the given pool
    }
}