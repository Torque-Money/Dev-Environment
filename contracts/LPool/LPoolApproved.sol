//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPoolCore.sol";
import "./LPoolToken.sol";

abstract contract LPoolApproved is LPoolCore {
    mapping(IERC20 => bool) private _PATokens;
    mapping(IERC20 => bool) private _LPTokens;

    mapping(IERC20 => IERC20) private _PAToLP;
    mapping(IERC20 => IERC20) private _LPToPA;

    modifier onlyPA(IERC20 token_) {
        require(isPA(token_), "Only pool approved tokens may be used");
        _;
    }

    modifier onlyLP(IERC20 token_) {
        require(isLP(token_), "Only liquidity pool tokens may be used");
        _;
    }

    // Check if a token regular token is approved
    function isPA(IERC20 token_) public view returns (bool) {
        return _PATokens[token_];
    }

    // Check if a given token is an LP token
    function isLP(IERC20 token_) public view returns (bool) {
        return _LPTokens[token_];
    }

    // Approve a token for use with the pool and create a new LP token
    function approve(IERC20[] memory token_, string[] memory name_, string[] memory symbol_) external onlyRole(POOL_ADMIN) {
        for (uint i = 0; i < token_.length; i++) {
            if (!isPA(token_[i]) && !isLP(token_[i])) {
                _PATokens[token_[i]] = true;

                IERC20 LPToken = IERC20(address(new LPoolToken(name_[i], symbol_[i]))); 
                _LPTokens[LPToken] = true;

                _PAToLP[token_[i]] = LPToken;
                _LPToPA[LPToken] = token_[i];

                emit TokenApproved(token_[i], LPToken);
            }
        }
    } 

    // Get the LP token that corresponds to the given token
    function LPFromPA(IERC20 token_) public view onlyPA(token_) returns (IERC20) {
        return _PAToLP[token_];
    }

    // Get the token that corresponds to the given LP token
    function PAFromLP(IERC20 token_) public view onlyLP(token_) returns (IERC20) {
        return _LPToPA[token_];
    }

    event TokenApproved(IERC20 token, IERC20 LPToken);
}