//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IsoMarginCore.sol";

abstract contract IsoMarginPool is IsoMarginCore {
    mapping(IERC20 => uint256) private _totalBorrowed;
    mapping(IERC20 => uint256) private _totalCollateral;

    // Get the total borrowed of a given asset
    function totalBorrowed(IERC20 _token) external view returns (uint256) {
        return _totalBorrowed[_token];
    }

    // Get the total collateral of a given asset
    function totalCollateral(IERC20 _token) external view returns (uint256) {
        return _totalCollateral[_token];
    }

    // Set the total borrowed of a given asset
    function setTotalBorrowed(IERC20 _token, uint256 _amount) public {
        _totalBorrowed[_token] = _amount;
    }

    // Set the total borrowed of a given asset
    function setTotalCollateral(IERC20 _token, uint256 _amount) public {
        _totalCollateral[_token] = _amount;
    }
}