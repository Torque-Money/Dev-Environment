//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginCore.sol";

abstract contract MarginPool is MarginCore {
    mapping(IERC20 => uint256) private _totalBorrowed;
    mapping(IERC20 => uint256) private _totalCollateral;

    // Get the total borrowed of a given asset
    function totalBorrowed(IERC20 borrowed_) public view returns (uint256) {
        return _totalBorrowed[borrowed_];
    }

    // Get the total collateral of a given asset
    function totalCollateral(IERC20 collateral_) public view returns (uint256) {
        return _totalCollateral[collateral_];
    }

    // Set the total borrowed of a given asset
    function setTotalBorrowed(IERC20 borrowed_, uint256 amount_) public {
        _totalBorrowed[borrowed_] = amount_;
    }

    // Set the total collateral of a given asset
    function setTotalCollateral(IERC20 collateral_, uint256 amount_) public {
        _totalCollateral[collateral_] = amount_;
    }
}
