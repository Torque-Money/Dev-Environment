//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginApproved.sol";

abstract contract MarginPool is MarginApproved {
    mapping(IERC20 => uint256) private _totalBorrowed;
    mapping(IERC20 => uint256) private _totalCollateral;

    // Get the total borrowed of a given asset
    function totalBorrowed(IERC20 token_) public view returns (uint256) {
        return _totalBorrowed[token_];
    }

    // Get the total collateral of a given asset
    function totalCollateral(IERC20 token_) public view returns (uint256) {
        return _totalCollateral[token_];
    }

    // Set the total borrowed of a given asset
    function _setTotalBorrowed(IERC20 token_, uint256 amount_) internal {
        _totalBorrowed[token_] = amount_;
    }

    // Set the total collateral of a given asset
    function _setTotalCollateral(IERC20 token_, uint256 amount_) internal {
        _totalCollateral[token_] = amount_;
    }
}
