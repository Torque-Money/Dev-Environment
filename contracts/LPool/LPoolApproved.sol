//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {LPoolCore} from "./LPoolCore.sol";

abstract contract LPoolApproved is LPoolCore {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(address => address) private _PTToLP;
    mapping(address => address) private _LPToPT;

    EnumerableSetUpgradeable.AddressSet private _PTSet;

    mapping(address => bool) private _approved;

    // Check if a token is usable with the pool
    function isPT(address token_) public view returns (bool) {
        return _PTToLP[token_] != address(0);
    }

    // Check if a pool token is approved
    function isApprovedPT(address token_) public view returns (bool) {
        return isPT(token_) && _approved[token_];
    }

    // Check if a given token is an LP token
    function isLP(address token_) public view returns (bool) {
        return _LPToPT[token_] != address(0);
    }

    // Check if a LP token is approved
    function isApprovedLP(address token_) public view returns (bool) {
        return isLP(token_) && _approved[PTFromLP(token_)];
    }

    // Add a new token to be used with the pool
    function addLPToken(address[] memory token_, address[] memory lpToken_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!isPT(token_[i]) && !isLP(lpToken_[i])) {
                _PTToLP[token_[i]] = lpToken_[i];
                _LPToPT[lpToken_[i]] = token_[i];
            }
        }
    }

    // Get a list of pool tokens
    function _poolTokens() internal view returns (address[] memory) {
        return _PTSet.values();
    }

    // Approve pool tokens for use with the pool if it is different to its current approved state - a LP token is approved if and only if its pool token is approved
    function setApproved(address[] memory token_, bool[] memory approved_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _approved[token_[i]] = approved_[i];

                if (_approved[token_[i]] && !_PTSet.contains(token_[i])) _PTSet.add(token_[i]);
                else if (!_approved[token_[i]] && _PTSet.contains(token_[i])) _PTSet.remove(token_[i]);
            }
        }
    }

    // Get the LP token that corresponds to the given token
    function LPFromPT(address token_) public view onlyPT(token_) returns (address) {
        return _PTToLP[token_];
    }

    // Get the token that corresponds to the given LP token
    function PTFromLP(address token_) public view onlyLP(token_) returns (address) {
        return _LPToPT[token_];
    }

    modifier onlyPT(address token_) {
        require(isPT(token_), "LPoolApproved: Only pool tokens may be used");
        _;
    }

    modifier onlyApprovedPT(address token_) {
        require(isApprovedPT(token_), "LPoolApproved: Only approved pool tokens may be used");
        _;
    }

    modifier onlyLP(address token_) {
        require(isLP(token_), "LPoolApproved: Only liquidity pool tokens may be used");
        _;
    }

    modifier onlyApprovedLP(address token_) {
        require(isApprovedLP(token_), "LPoolApproved: Only approved liquidity pool tokens may be used");
        _;
    }
}
