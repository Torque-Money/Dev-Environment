//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolCore.sol";
import "./LPoolToken.sol";

abstract contract LPoolApproved is LPoolCore {
    using SafeMath for uint256; 
    using SafeERC20 for IERC20;
    using SafeERC20 for LPoolToken;

    mapping(IERC20 => bool) private _approvedTokens;
    mapping(LPoolToken => bool) private _approvedLPTokens;

    mapping(IERC20 => LPoolToken) private _tokenToLPToken;
    mapping(LPoolToken => IERC20) private _LPTokenToToken;

    modifier approvedTokenOnly(IERC20 _token) {
        require(isApprovedToken(_token), "Only approved tokens may be used");
        _;
    }

    modifier approvedLPTokenOnly(LPoolToken _token) {
        require(isLPToken(_token), "Only LP tokens may be used");
        _;
    }

    // Check if a token regular token is approved
    function isApprovedToken(IERC20 _token) public view returns (bool) {
        return _approvedTokens[_token];
    }

    // Check if a given token is an LP token
    function isLPToken(LPoolToken _token) public view returns (bool) {
        return _approvedLPTokens[_token];
    }

    // Approve a token for use with the pool and create a new LP token
    function approve(IERC20 _token, string memory _name, string memory _symbol) external onlyRole(POOL_ADMIN) {
        require(!isApprovedToken(_token) && !isLPToken(LPoolToken(address(_token))), "This token is already in use with the pool");
        _approvedTokens[_token] = true;

        LPoolToken LPToken = new LPoolToken(_name, _symbol); 
        _approvedLPTokens[LPToken] = true;

        _tokenToLPToken[_token] = LPToken;
        _LPTokenToToken[LPToken] = _token;

        emit TokenApproved(_token, LPToken);
    } 

    // Get the LP token equivalent of a given token
    function getLPTokenFromToken(IERC20 _token) public view approvedTokenOnly(_token) returns (LPoolToken) {
        return _tokenToLPToken[_token];
    }

    function getTokenFromLPToken(LPoolToken _token) public view approvedLPTokenOnly(_token) returns (IERC20) {
        return _LPTokenToToken[_token];
    }

    event TokenApproved(IERC20 token, LPoolToken LPToken);
}