//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolApproved.sol";

abstract contract LPoolManipulation is LPoolApproved {
    // Claim an amount of a given token
    function claim(IERC20 _token) external onlyRole(POOL_APPROVED) {

    }

    // Unclaim an amount of a given token
    function unclaim(IERC20 _token) external onlyRole(POOL_APPROVED) {

    }

    // Deposit a given amount of collateral into the pool
    function deposit(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) {

    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) {
        
    }
}