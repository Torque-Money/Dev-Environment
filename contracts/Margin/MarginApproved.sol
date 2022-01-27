//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(address => bool) private _collateralTokens;
    mapping(address => bool) private _borrowedTokens;

    mapping(address => bool) private _approvedCollateralTokens;
    mapping(address => bool) private _approvedBorrowedTokens;

    modifier onlyApprovedCollateralToken(address token_) {
        require(isApprovedCollateralToken(token_), "MarginApproved: Only approved collateral tokens may be used");
        _;
    }

    modifier onlyApprovedBorrowedToken(address token_) {
        require(isApprovedBorrowedToken(token_), "MarginApproved: Only approved borrowed tokens may be used");
        _;
    }

    modifier onlyCollateralToken(address token_) {
        require(isCollateralToken(token_), "MarginApproved: Only collateral tokens may be used");
        _;
    }

    modifier onlyBorrowedToken(address token_) {
        require(isBorrowedToken(token_), "MarginApproved: Only borrowed tokens may be used");
        _;
    }

    // Add a collateral token
    function addCollateralToken(address[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!_collateralTokens[token_[i]]) {
                _collateralTokens[token_[i]] = true;
                emit AddCollateralToken(token_[i]);
            }
        }
    }

    // Add a borrowed token
    function addBorrowedToken(address[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!_borrowedTokens[token_[i]]) {
                _borrowedTokens[token_[i]] = true;
                emit AddBorrowedToken(token_[i]);
            }
        }
    }

    // Approve a token for collateral
    function setApprovedCollateralToken(address[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isCollateralToken(token_[i])) _approvedCollateralTokens[token_[i]] = approved_[i];
        }
    }

    // Approve a token to be used for borrowing
    function setApprovedBorrowedToken(address[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isBorrowedToken(token_[i])) _approvedBorrowedTokens[token_[i]] = approved_[i];
        }
    }

    // Check if a token is a collateral token
    function isCollateralToken(address token_) public view returns (bool) {
        return _collateralTokens[token_];
    }

    // Check if a token is a borrowed token
    function isBorrowedToken(address token_) public view returns (bool) {
        return _borrowedTokens[token_];
    }

    // Check if a token is an approved collateral token
    function isApprovedCollateralToken(address token_) public view returns (bool) {
        return isCollateralToken(token_) && _approvedCollateralTokens[token_];
    }

    // Check if a token is an approved borrowed token
    function isApprovedBorrowedToken(address token_) public view returns (bool) {
        return isBorrowedToken(token_) && _approvedBorrowedTokens[token_];
    }

    event AddCollateralToken(address token);
    event AddBorrowedToken(address token);
}
