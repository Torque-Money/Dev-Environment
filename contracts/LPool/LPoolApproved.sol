//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolCore.sol";

abstract contract LPoolApproved is LPoolCore {
    using SafeMath for uint256; 
    using SafeERC20 for IERC20;

    mapping(IERC20 => bool) private _approved;
    mapping(IERC20 => IERC20) private _tokenToLPToken;
    mapping(IERC20 => IERC20) private _LPTokenToToken;

    modifier approvedOnly(IERC20 _token) {
        require(isApproved(_token), "Only approved tokens are allowed");
        _;
    }

    // Check if a token is approved
    function isApproved(IERC20 _token) public view returns (bool) {
        return _approved[_token];
    }

    // Approve a token for use with the pool and create a new LP token
    function approve(IERC20 _token) external onlyRole(POOL_ADMIN) {
        require(!isApproved(_token), "This token has already been approved");
        _approved[_token] = true;

        address newFarmToken = address(new PoolToken(_ltName, _ltSymbol, 0)); 

        emit TokenApproved(_token);
    } 

    // Get the equivalent token

    event TokenApproved(IERC20 token);
}