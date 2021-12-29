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
    function tvl(IERC20 token_) public view returns (uint256) {
        return token_.balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(IERC20 token_) public view returns (uint256) {
        uint256 claimed = _totalClaimed[token_];
        return tvl(token_).sub(claimed);
    }

    // Claim an amount of a given token
    function claim(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedToken(token_) {
        require(amount_ <= liquidity(token_), "Cannot claim more than total liquidity");
        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].add(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].add(amount_);
        emit Claim(_msgSender(), token_, amount_);
    }

    // Unclaim an amount of a given token
    function unclaim(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedToken(token_) {
        require(amount_ <= _claimed[_msgSender()][token_], "Cannot unclaim more than your claim");
        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].sub(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].sub(amount_);
        emit Unclaim(_msgSender(), token_, amount_);
    }

    // Deposit a given amount of collateral into the pool and transfer a portion as a tax to the tax account
    function deposit(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedToken(token_) {
        uint256 tax = taxPercent.mul(amount_).div(100);
        token_.safeTransferFrom(_msgSender(), taxAccount, tax);

        uint256 taxedAmount = amount_.sub(tax);
        token_.safeTransferFrom(_msgSender(), address(this), taxedAmount);
        emit Deposit(_msgSender(), token_, taxedAmount, tax, taxAccount);
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedToken(token_) {
        token_.safeTransfer(_msgSender(), amount_);
        emit Withdraw(_msgSender(), token_, amount_);
    }

    event Claim(address indexed account, IERC20 token, uint256 amount);
    event Unclaim(address indexed account, IERC20 token, uint256 amount);
    event Deposit(address indexed account, IERC20 token, uint256 amount, uint256 tax, address taxAccount);
    event Withdraw(address indexed account, IERC20 token, uint256 amount);
}