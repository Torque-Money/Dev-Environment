//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./YieldRates.sol";

// **** Might want to split this one up into multiple classes e.g. YieldAccount.sol

abstract contract YieldStake is YieldRates {
    function stake(IERC20 token_, uint256 amount_) external {

    }

    function stakedBalance(IERC20 token_, uint256 amount_) external {

    }

    function stakeValue(IERC20 token_, uint256 amount_) public view returns (uint256) {

    }

    function unstake() external {

    }

    event Stake();
    event Unstake();
}