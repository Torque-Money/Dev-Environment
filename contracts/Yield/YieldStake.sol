//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./YieldRates.sol";

abstract contract YieldStake is YieldRates {
    function stake() external {

    }

    function stakeValue() public view returns (uint256) {

    }

    function unstake() external {

    }

    event Stake();
    event Unstake();
}