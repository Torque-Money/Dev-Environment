//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./LPoolCore.sol";
import "./LPoolToken.sol";

abstract contract LPoolApproved is LPoolCore {
    mapping(address => address) private _PTToLP;
    mapping(address => address) private _LPToPT;

    address[] private _PTList;

    mapping(address => bool) private _approved;

    modifier onlyPT(IERC20Upgradeable token_) {
        require(isPT(token_), "LPoolApproved: Only pool tokens may be used");
        _;
    }

    modifier onlyApprovedPT(IERC20Upgradeable token_) {
        require(isApprovedPT(token_), "LPoolApproved: Only approved pool tokens may be used");
        _;
    }

    modifier onlyLP(IERC20Upgradeable token_) {
        require(isLP(token_), "LPoolApproved: Only liquidity pool tokens may be used");
        _;
    }

    modifier onlyApprovedLP(IERC20Upgradeable token_) {
        require(isApprovedLP(token_), "LPoolApproved: Only approved liquidity pool tokens may be used");
        _;
    }

    // Check if a token is usable with the pool
    function isPT(IERC20Upgradeable token_) public view returns (bool) {
        return _PTToLP[address(token_)] != address(0);
    }

    // Check if a pool token is approved
    function isApprovedPT(IERC20Upgradeable token_) public view returns (bool) {
        return isPT(token_) && _approved[address(token_)];
    }

    // Check if a given token is an LP token
    function isLP(IERC20Upgradeable token_) public view returns (bool) {
        return _LPToPT[address(token_)] != address(0);
    }

    // Check if a LP token is approved
    function isApprovedLP(IERC20Upgradeable token_) public view returns (bool) {
        return isLP(token_) && _approved[address(PTFromLP(token_))];
    }

    // Add a new token to be used with the pool
    function addLPToken(
        IERC20Upgradeable[] memory token_,
        string[] memory name_,
        string[] memory symbol_
    ) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!isPT(token_[i]) && !isLP(token_[i])) {
                address LPToken = address(new LPoolToken(name_[i], symbol_[i]));

                _PTToLP[address(token_[i])] = LPToken;
                _LPToPT[LPToken] = address(token_[i]);

                _PTList.push(address(token_[i]));

                emit AddLPToken(token_[i], IERC20Upgradeable(LPToken));
            }
        }
    }

    // Get a list of pool tokens
    function _poolTokens() internal view returns (IERC20Upgradeable[] memory) {
        IERC20Upgradeable[] memory tokens = new IERC20Upgradeable[](_PTList.length);
        for (uint256 i = 0; i < tokens.length; i++) tokens[i] = IERC20Upgradeable(_PTList[i]);
        return tokens;
    }

    // Approve pool tokens for use with the pool if it is different to its current approved state - a LP token is approved if and only if its pool token is approved
    function setApproved(IERC20Upgradeable[] memory token_, bool[] memory approved_) external onlyRole(POOL_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isPT(token_[i])) {
                _approved[token_[i]] = approved_[i];
            }
        }
    }

    // Get the LP token that corresponds to the given token
    function LPFromPT(IERC20Upgradeable token_) public view onlyPT(token_) returns (IERC20Upgradeable) {
        return _PTToLP[token_];
    }

    // Get the token that corresponds to the given LP token
    function PTFromLP(IERC20Upgradeable token_) public view onlyLP(token_) returns (IERC20Upgradeable) {
        return _LPToPT[token_];
    }

    event AddLPToken(IERC20Upgradeable token, IERC20Upgradeable LPToken);
}
