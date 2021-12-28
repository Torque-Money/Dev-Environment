//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolApproved.sol";

abstract contract LPoolManipulation is LPoolApproved {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => mapping(IERC20 => uint256)) private _claimed;
    mapping(IERC20 => uint256) private _totalClaimed;

    // Get the available liquidity of the pool
    function liquidity(IERC20 _token) public view returns (uint256) {
        uint256 balance = _token.balanceOf(address(this));
        uint256 claimed = _totalClaimed[_token];
        return balance.sub(claimed);
    }

    // Get the utlization percentage of the pool
    function utilization(IERC20 _token) public view returns (uint256) {
        uint256 balance = _token.balanceOf(address(this));
        uint256 claimed = _totalClaimed[_token];
        return claimed.mul(100).div(balance);
    }

    // Claim an amount of a given token
    function claim(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) {
        require(_amount <= liquidity(_token), "Cannot claim more than total liquidity");
        _claimed[_msgSender()][_token] = _claimed[_msgSender()][_token].add(_amount);
        _totalClaimed[_token] = _totalClaimed[_token].add(_amount);
    }

    // Unclaim an amount of a given token
    function unclaim(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) {
        require(_amount <= _claimed[_msgSender()][_token], "Cannot unclaim more than your claim");
        _claimed[_msgSender()][_token] = _claimed[_msgSender()][_token].sub(_amount);
        _totalClaimed[_token] = _totalClaimed[_token].sub(_amount);
    }

    // Deposit a given amount of collateral into the pool
    function deposit(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) {
        require(isApprovedToken(_token) || isLPToken(_token), "May only deposit approved tokens to the pool");
        if (isApprovedToken(_token)) {

        } else {
            // Manually burn the tokens and reconvert them to the appropriate asset
        }
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) {

    }
}