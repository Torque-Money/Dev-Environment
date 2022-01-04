//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolApproved.sol";

abstract contract LPoolClaim is LPoolApproved  {
    using SafeMath for uint256;

    mapping(address => mapping(IERC20 => uint256)) private _claimed;
    mapping(IERC20 => uint256) private _totalClaimed;

    // Claim an amount of a given token
    function claim(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyPA(token_) {
        require(amount_ <= liquidity(token_), "Cannot claim more than total liquidity");
        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].add(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].add(amount_);
        emit Claim(_msgSender(), token_, amount_);
    }

    // Unclaim an amount of a given token
    function unclaim(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyPA(token_) {
        require(amount_ <= _claimed[_msgSender()][token_], "Cannot unclaim more than your claim");
        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].sub(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].sub(amount_);
        emit Unclaim(_msgSender(), token_, amount_);
    }

    // Get the amount an account has claimed
    function claimed(IERC20 token_, address account_) external view returns (uint256) {
        return _claimed[account_][token_];
    }

    // Get the total amount claimed
    function totalClaimed(IERC20 token_) public view returns (uint256) {
        return _totalClaimed[token_];
    }

    function liquidity(IERC20 token_) public view virtual returns (uint256);

    event Claim(address indexed account, IERC20 token, uint256 amount);
    event Unclaim(address indexed account, IERC20 token, uint256 amount);
}