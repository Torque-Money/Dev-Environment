//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolApproved.sol";
import "./LPoolTax.sol";

abstract contract LPoolManipulation is LPoolApproved, LPoolTax {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => mapping(IERC20 => uint256)) private _claimed;
    mapping(IERC20 => uint256) private _totalClaimed;

    // Return the total value locked of a given asset
    function tvl(IERC20 _token) public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(IERC20 _token) public view returns (uint256) {
        uint256 claimed = _totalClaimed[_token];
        return tvl(_token).sub(claimed);
    }

    // Get the utlization percentage of the pool
    function utilization(IERC20 _token) public view returns (uint256) {
        uint256 claimed = _totalClaimed[_token];
        return claimed.mul(100).div(tvl(_token));
    }

    // Claim an amount of a given token
    function claim(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApprovedToken(_token) {
        require(_amount <= liquidity(_token), "Cannot claim more than total liquidity");
        _claimed[_msgSender()][_token] = _claimed[_msgSender()][_token].add(_amount);
        _totalClaimed[_token] = _totalClaimed[_token].add(_amount);
        emit Claim(_msgSender(), _token, _amount);
    }

    // Unclaim an amount of a given token
    function unclaim(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApprovedToken(_token) {
        require(_amount <= _claimed[_msgSender()][_token], "Cannot unclaim more than your claim");
        _claimed[_msgSender()][_token] = _claimed[_msgSender()][_token].sub(_amount);
        _totalClaimed[_token] = _totalClaimed[_token].sub(_amount);
        emit Unclaim(_msgSender(), _token, _amount);
    }

    // Deposit a given amount of collateral into the pool and transfer a portion as a tax to the tax account
    function deposit(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApprovedToken(_token) {
        uint256 tax = taxPercent.mul(_amount).div(100);
        _token.safeTransferFrom(_msgSender(), taxAccount, tax);

        uint256 taxedAmount = _amount.sub(tax);
        _token.safeTransferFrom(_msgSender(), address(this), taxedAmount);
        emit Deposit(_msgSender(), _token, taxedAmount, tax, taxAccount);
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(IERC20 _token, uint256 _amount) external onlyRole(POOL_APPROVED) onlyApprovedToken(_token) {
        _token.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _token, _amount);
    }

    event Claim(address indexed account, IERC20 token, uint256 amount);
    event Unclaim(address indexed account, IERC20 token, uint256 amount);
    event Deposit(address indexed account, IERC20 token, uint256 amount, uint256 tax, address taxAccount);
    event Withdraw(address indexed account, IERC20 token, uint256 amount);
}