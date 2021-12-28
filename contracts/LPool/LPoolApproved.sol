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

    modifier approvedTokenOnly(IERC20 _token) {
        require(isApprovedToken(_token), "Only approved tokens may be used");
        _;
    }

    modifier LPTokenOnly(IERC20 _token) {
        require(isLPToken(_token), "Only LP tokens may be used");
        _;
    }

    // Check if a token regular token is approved
    function isApprovedToken(IERC20 _token) public view returns (bool) {
        return _approvedTokens[_token];
    }

    // Check if a given token is an LP token
    function isLPToken(IERC20 _token) public view returns (bool) {
        return _approvedLPTokens[_token];
    }

    // Approve a token for use with the pool and create a new LP token
    function approve(IERC20 _token, string memory _name, string memory _symbol) external onlyRole(POOL_ADMIN) {
        require(!isApprovedToken(_token) && !isLPToken(_token), "This token is already approved by the pool");
        _approvedTokens[_token] = true;

        IERC20 LPToken = IERC20(address(new LPoolToken(_name, _symbol))); 
        _approvedLPTokens[LPToken] = true;

        _tokenToLPToken[_token] = LPToken;
        _LPTokenToToken[LPToken] = _token;

        emit TokenApproved(_token, LPToken);
    } 

    // Get the LP token that corresponds to the given token
    function getLPTokenFromToken(IERC20 _token) public view approvedTokenOnly(_token) returns (IERC20) {
        return _tokenToLPToken[_token];
    }

    // Get the token that corresponds to the given LP token
    function getTokenFromLPToken(IERC20 _token) public view LPTokenOnly(_token) returns (IERC20) {
        return _LPTokenToToken[_token];
    }

    event TokenApproved(IERC20 token, IERC20 LPToken);
}