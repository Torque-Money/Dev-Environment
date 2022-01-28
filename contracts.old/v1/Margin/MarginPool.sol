//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarginApproved.sol";

abstract contract MarginPool is MarginApproved {
    mapping(address => uint256) private _totalBorrowed;
    mapping(address => uint256) private _totalCollateral;

    // Get the total borrowed of a given asset
    function totalBorrowed(address token_) public view onlyBorrowedToken(token_) returns (uint256) {
        return _totalBorrowed[token_];
    }

    // Get the total collateral of a given asset
    function totalCollateral(address token_) public view onlyCollateralToken(token_) returns (uint256) {
        return _totalCollateral[token_];
    }

    // Set the total borrowed of a given asset
    function _setTotalBorrowed(address token_, uint256 amount_) internal {
        _totalBorrowed[token_] = amount_;
    }

    // Set the total collateral of a given asset
    function _setTotalCollateral(address token_, uint256 amount_) internal {
        _totalCollateral[token_] = amount_;
    }
}
