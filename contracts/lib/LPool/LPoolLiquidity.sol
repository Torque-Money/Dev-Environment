//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolCore.sol";
import "./LPoolPeriod.sol";

abstract contract LPoolLiquidity is LPoolCore, LPoolPeriod {
    using SafeMath for uint256;

    /** @dev Get the total amount of deposited assets into the given pool */
    function deposited(IERC20 _token, uint256 _periodId) external view returns (uint256) {
        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];
        return stakingPeriod.totalDeposited;
    }

    // **** Here is the problem with this - we need a TVL and a different liquidity, because now this would be affecting the utilization and interest rates

    /** @dev Returns the total liquidity of a given token locked for the current period */
    function tvl(IERC20 _token, uint256 _periodId) external view returns (uint256) {
        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];
        return stakingPeriod.liquidity;
    }

    /** @dev Returns the total locked liquidity for the current period */
    function liquidity(IERC20 _token, uint256 _periodId) public view returns (uint256) {
        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];
        if (isCurrentPeriod(_periodId)) return stakingPeriod.liquidity.sub(stakingPeriod.totalClaimed);
        return stakingPeriod.liquidity;
    }
}