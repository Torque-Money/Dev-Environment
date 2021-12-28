//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolApproved.sol";

abstract contract LPoolStake is LPoolApproved {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Stake tokens and receive LP tokens that represent the users share in the pool
    function stake(IERC20 _token, uint256 _amount) external onlyApprovedToken(_token) {

    }

    // Get the value for redeeming LP tokens for the underlying asset
    function redeemValue(IERC20 _token, uint256 _amount) public view onlyLPToken(_token) returns (uint256) {

    }

    // Redeem LP tokens for the underlying asset
    function redeem(IERC20 _token, uint256 _amount) external onlyLPToken(_token) {

    }

    event Stake();
    event Redeem();
}