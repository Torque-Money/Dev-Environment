//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPoolCore.sol";
import "./LPoolToken.sol";

abstract contract LPoolApproved is LPoolCore {
    mapping(IERC20 => IERC20) private _PTToLP;
    mapping(IERC20 => IERC20) private _LPToPT;

    IERC20[] private _PTList;

    mapping(IERC20 => bool) private _approved;

    modifier onlyPT(IERC20 token_) {
        require(isPT(token_), "Only pool tokens may be used");
        _;
    }

    modifier onlyApprovedPT(IERC20 token_) {
        require(isApprovedPT(token_), "Only approved pool tokens may be used");
        _;
    }

    modifier onlyLP(IERC20 token_) {
        require(isLP(token_), "Only liquidity pool tokens may be used");
        _;
    }

    modifier onlyApprovedLP(IERC20 token_) {
        require(isApprovedLP(token_), "Only approved liquidity pool tokens may be used");
        _;
    }

    // Check if a token is usable with the pool
    function isPT(IERC20 token_) public view returns (bool) {
        return address(_PTToLP[token_]) != address(0);
    }

    // Check if a pool token is approved
    function isApprovedPT(IERC20 token_) public view returns (bool) {
        return isPT(token_) && _approved[token_];
    }

    // Check if a given token is an LP token
    function isLP(IERC20 token_) public view returns (bool) {
        return address(_LPToPT[token_]) != address(0);
    }

    // Check if a LP token is approved
    function isApprovedLP(IERC20 token_) public view returns (bool) {
        return isLP(token_) && _approved[PTFromLP(token_)];
    }

    // Add a new token to be used with the pool
    function addLPToken(
        IERC20[] memory token_,
        string[] memory name_,
        string[] memory symbol_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!isPT(token_[i]) && !isLP(token_[i])) {
                IERC20 LPToken = IERC20(address(new LPoolToken(name_[i], symbol_[i])));

                _PTToLP[token_[i]] = LPToken;
                _LPToPT[LPToken] = token_[i];

                _PTList.push(token_[i]);

                emit AddLPToken(token_[i], LPToken);
            }
        }
    }

    // Get a list of pool tokens
    function _poolTokens() internal view returns (IERC20[] memory) {
        return _PTList;
    }

    // Approve pool tokens for use with the pool if it is different to its current approved state - a LP token is approved if and only if its pool token is approved
    function setApproved(IERC20[] memory token_, bool[] memory approved_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _approved[token_[i]] = approved_[i];
            }
        }
    }

    // Get the LP token that corresponds to the given token
    function LPFromPT(IERC20 token_) public view onlyPT(token_) returns (IERC20) {
        return _PTToLP[token_];
    }

    // Get the token that corresponds to the given LP token
    function PTFromLP(IERC20 token_) public view onlyLP(token_) returns (IERC20) {
        return _LPToPT[token_];
    }

    event AddLPToken(IERC20 token, IERC20 LPToken);
}
