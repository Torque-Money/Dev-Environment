//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginCore} from "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(address => bool) private _collateralTokens;
    mapping(address => bool) private _borrowTokens;

    mapping(address => bool) private _approvedCollateralTokens;
    mapping(address => bool) private _approvedBorrowTokens;

    // Add a collateral token
    function addCollateralToken(address[] memory token_) public onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) if (!isCollateralToken(token_[i])) _collateralTokens[token_[i]] = true;
    }

    // Add a borrow token
    function addBorrowToken(address[] memory token_) external onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) if (!isBorrowToken(token_[i])) _borrowTokens[token_[i]] = true;
        addCollateralToken(token_);
    }

    // Approve a token for collateral
    function setApprovedCollateralToken(address[] memory token_, bool[] memory approved_) external onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isCollateralToken(token_[i])) _approvedCollateralTokens[token_[i]] = approved_[i];
        }
    }

    // Approve a borrow token
    function setApprovedBorrowToken(address[] memory token_, bool[] memory approved_) external onlyRole(MARGIN_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isBorrowToken(token_[i])) _approvedBorrowTokens[token_[i]] = approved_[i];
        }
    }

    // Check if a token is a collateral token
    function isCollateralToken(address token_) public view returns (bool) {
        return _collateralTokens[token_];
    }

    // Check if a token is a borrow token
    function isBorrowToken(address token_) public view returns (bool) {
        return _borrowTokens[token_];
    }

    // Check if a token is an approved collateral token
    function isApprovedCollateralToken(address token_) public view returns (bool) {
        return isCollateralToken(token_) && _approvedCollateralTokens[token_];
    }

    // Check if a token is an approved borrow token
    function isApprovedBorrowToken(address token_) public view returns (bool) {
        return isBorrowToken(token_) && _approvedBorrowTokens[token_];
    }

    modifier onlyCollateralToken(address token_) {
        require(isCollateralToken(token_), "MarginApproved: Only collateral tokens may be used");
        _;
    }

    modifier onlyBorrowToken(address token_) {
        require(isBorrowToken(token_), "MarginApproved: Only borrow tokens may be used");
        _;
    }

    modifier onlyApprovedCollateralToken(address token_) {
        require(isApprovedCollateralToken(token_), "MarginApproved: Only approved collateral tokens may be used");
        _;
    }

    modifier onlyApprovedBorrowToken(address token_) {
        require(isApprovedBorrowToken(token_), "MarginApproved: Only approved borrow tokens may be used");
        _;
    }
}
