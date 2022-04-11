//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {LPoolApproved} from "./LPoolApproved.sol";

abstract contract LPoolClaim is LPoolApproved {
    using SafeMathUpgradeable for uint256;

    mapping(address => mapping(address => uint256)) private _claimed;
    mapping(address => uint256) private _totalClaimed;

    // Claim an amount of a given token
    function claim(address token_, uint256 amount_) external whenNotPaused onlyRole(POOL_ADMIN) onlyApprovedPT(token_) {
        require(amount_ > 0, "LPoolClaim: claim amount must be greater than 0");
        require(amount_ <= liquidity(token_), "LPoolClaim: Cannot claim more than total liquidity");

        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].add(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].add(amount_);
    }

    // Unclaim an amount of a given token
    function unclaim(address token_, uint256 amount_) external whenNotPaused onlyRole(POOL_ADMIN) onlyPT(token_) {
        require(amount_ > 0, "LPoolClaim: Unclaim amount must be greater than 0");
        require(amount_ <= _claimed[_msgSender()][token_], "LPoolClaim: Cannot unclaim more than current claim");

        _claimed[_msgSender()][token_] = _claimed[_msgSender()][token_].sub(amount_);
        _totalClaimed[token_] = _totalClaimed[token_].sub(amount_);
    }

    // Get the total amount claimed
    function _totalAmountClaimed(address token_) internal view returns (uint256) {
        return _totalClaimed[token_];
    }

    function liquidity(address token_) public view virtual returns (uint256);
}
