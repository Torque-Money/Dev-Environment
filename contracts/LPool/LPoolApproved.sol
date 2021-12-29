//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPoolCore.sol";
import "./LPoolToken.sol";

abstract contract LPoolApproved is LPoolCore {
    mapping(IERC20 => bool) private _approvedTokens;
    mapping(IERC20 => bool) private _approvedLPTokens;

    mapping(IERC20 => IERC20) private _tokenToLPToken;
    mapping(IERC20 => IERC20) private _LPTokenToToken;

    modifier onlyApprovedToken(IERC20 token_) {
        require(isApprovedToken(token_), "Only approved tokens may be used");
        _;
    }

    modifier onlyLPToken(IERC20 token_) {
        require(isLPToken(token_), "Only LP tokens may be used");
        _;
    }

    // Check if a token regular token is approved
    function isApprovedToken(IERC20 token_) public view returns (bool) {
        return _approvedTokens[token_];
    }

    // Check if a given token is an LP token
    function isLPToken(IERC20 token_) public view returns (bool) {
        return _approvedLPTokens[token_];
    }

    // Approve a token for use with the pool and create a new LP token
    function approve(IERC20 token_, string memory name_, string memory symbol_) external onlyRole(POOL_ADMIN) {
        require(!isApprovedToken(token_) && !isLPToken(token_), "This token is already approved by the pool");
        _approvedTokens[token_] = true;

        IERC20 LPToken = IERC20(address(new LPoolToken(name_, symbol_))); 
        _approvedLPTokens[LPToken] = true;

        _tokenToLPToken[token_] = LPToken;
        _LPTokenToToken[LPToken] = token_;

        emit TokenApproved(token_, LPToken);
    } 

    // Get the LP token that corresponds to the given token
    function LPTokenFromToken(IERC20 token_) public view onlyApprovedToken(token_) returns (IERC20) {
        return _tokenToLPToken[token_];
    }

    // Get the token that corresponds to the given LP token
    function tokenFromLPToken(IERC20 token_) public view onlyLPToken(token_) returns (IERC20) {
        return _LPTokenToToken[token_];
    }

    event TokenApproved(IERC20 token, IERC20 LPToken);
}