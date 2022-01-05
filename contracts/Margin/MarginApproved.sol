//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(IERC20 => bool) private _approved;

    modifier onlyPA(IERC20 token_) {
        require(pool.isPA(token_), "Only pool approved tokens may be used");
        _;
    }

    modifier onlyApproved(IERC20 token_) {
        require(isApproved(token_), "Only approved tokens may be used");
        _;
    }

    // Approve a token for use with the pool and create a new LP token
    function approve(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint i = 0; i < token_.length; i++) {
            if (isApproved(token_[i]) != approved_[i]) {
                _approved[token_[i]] = approved_[i];
                emit ApprovedTokenUpdate(token_[i], approved_[i]);
            }
        }
    }

    // Check if a token is approved
    function isApproved(IERC20 token_) public view returns (bool) {
        return _approved[token_];
    }

    event ApprovedTokenUpdate(IERC20 token, bool approved);
}