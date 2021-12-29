//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginPool.sol";

abstract contract IsoMarginAccount is IsoMarginPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct IsolatedMargin {
        uint256 collateral;
        uint256 borrowed;
        uint256 initialBorrowPrice; // Price of borrowed in terms of collateral
        uint256 initialBorrowBlock;
    }

    mapping(IERC20 => mapping(address => mapping(IERC20 => IsolatedMargin))) private _isolatedMargins;

    mapping(IERC20 => mapping(address => uint256)) private _borrowed;
    mapping(IERC20 => mapping(address => uint256)) private _collateral;

    // Get the borrowed for a given account for a given asset
    function borrowed(IERC20 _token, address _account) external view returns (uint256) {
        return _borrowed[_token][_account];
    }

    // Get the borrowed for a given account against some collateral for a given asset
    function borrowed(IERC20 _collateral, IERC20 _borrowed, address _account) external view returns (uint256) {
        return _isolatedMargins[_borrowed][_account][_collateral].borrowed;
    }

    // Get the collateral of a given account for a given asset
    function collateral(IERC20 _token, address _account) external view returns (uint256) {
        return _collateral[_token][_account];
    }

    // Get the collateral for a given account against some borrowed asset
    function collateral(IERC20 _collateral, IERC20 _borrowed, address _account) external view returns (uint256) {
        return _isolatedMargins[_borrowed][_account][_collateral].collateral;
    }
}