//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {LPoolClaim} from "./LPoolClaim.sol";
import {LPoolDeposit} from "./LPoolDeposit.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit {
    using SafeMathUpgradeable for uint256;

    // Return the total amount locked of a given asset
    function totalAmountLocked(address token_) public view onlyPT(token_) returns (uint256) {
        return IERC20Upgradeable(token_).balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(address token_) public view override(LPoolClaim, LPoolDeposit) onlyPT(token_) returns (uint256) {
        return totalAmountLocked(token_).sub(_totalAmountClaimed(token_));
    }

    // Get the total utilized in the pool
    function utilized(address token_) public view override onlyPT(token_) returns (uint256) {
        return totalAmountLocked(token_).sub(liquidity(token_));
    }

    // Get the utilization rate for a given asset
    function utilizationRate(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        return (utilized(token_), totalAmountLocked(token_));
    }
}
