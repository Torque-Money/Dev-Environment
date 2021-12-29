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
    function borrowed(IERC20 token_, address account_) external view returns (uint256) {
        return _borrowed[token_][account_];
    }

    // Get the borrowed for a given account against some collateral for a given asset
    function borrowed(IERC20 collateral_, IERC20 borrowed_, address account_) public view returns (uint256) {
        return _isolatedMargins[borrowed_][account_][collateral_].borrowed;
    }

    // Set the amount the user has borrowed
    function _setBorrowed(IERC20 collateral_, IERC20 borrowed_, uint256 amount_, address account_) internal {
        IsolatedMargin storage isolatedMargin = _isolatedMargins[collateral_][account_][borrowed_];

        setTotalBorrowed(borrowed_, totalBorrowed(borrowed_).sub(isolatedMargin.borrowed).add(amount_));
        _borrowed[borrowed_][account_] = _borrowed[borrowed_][account_].sub(isolatedMargin.borrowed).add(amount_);
        isolatedMargin.borrowed = amount_;
    }

    // Get the collateral of a given account for a given asset
    function collateral(IERC20 token_, address account_) external view returns (uint256) {
        return _collateral[token_][account_];
    }

    // Get the collateral for a given account against some borrowed asset
    function collateral(IERC20 collateral_, IERC20 borrowed_, address account_) public view returns (uint256) {
        return _isolatedMargins[borrowed_][account_][collateral_].collateral;
    }

    // Set the collateral for a user
    function _setCollateral(IERC20 collateral_, IERC20 borrowed_, uint256 amount_, address account_) internal {
        IsolatedMargin storage isolatedMargin = _isolatedMargins[collateral_][account_][borrowed_];

        setTotalCollateral(collateral_, totalCollateral(collateral_).sub(isolatedMargin.collateral).add(amount_));
        _collateral[collateral_][account_] = _collateral[collateral_][account_].sub(isolatedMargin.collateral).add(amount_);
        isolatedMargin.collateral = amount_;
    }

    // Get the initial borrow price for an account
    function _initialBorrowPrice(IERC20 collateral_, IERC20 borrowed_, address account_) internal view returns (uint256) {
        IsolatedMargin storage isolatedMargin = _isolatedMargins[collateral_][account_][borrowed_];
        return isolatedMargin.initialBorrowPrice;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowPrice(IERC20 collateral_, IERC20 borrowed_, uint256 price_, address account_) internal {
        IsolatedMargin storage isolatedMargin = _isolatedMargins[collateral_][account_][borrowed_];
        isolatedMargin.initialBorrowPrice = price_;
    }

    // Get the initial borrow block for an ccount
    function _initialBorrowBlock(IERC20 collateral_, IERC20 borrowed_, address account_) internal view returns (uint256) {
        IsolatedMargin storage isolatedMargin = _isolatedMargins[collateral_][account_][borrowed_];
        return isolatedMargin.initialBorrowBlock;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowBlock(IERC20 collateral_, IERC20 borrowed_, uint256 block_, address account_) internal {
        IsolatedMargin storage isolatedMargin = _isolatedMargins[collateral_][account_][borrowed_];
        isolatedMargin.initialBorrowBlock = block_;
    }
}