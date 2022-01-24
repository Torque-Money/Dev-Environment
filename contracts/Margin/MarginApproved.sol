//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(IERC20 => bool) private _collateralTokens;
    mapping(IERC20 => bool) private _borrowedTokens;

    mapping(IERC20 => bool) private _approvedCollateralTokens;
    mapping(IERC20 => bool) private _approvedBorrowedTokens;

    modifier onlyApprovedCollateralToken(IERC20 token_) {
        require(isApprovedCollateralToken(token_), "MarginApproved: Only approved collateral tokens may be used");
        _;
    }

    modifier onlyApprovedBorrowedToken(IERC20 token_) {
        require(isApprovedBorrowedToken(token_), "MarginApproved: Only approved borrowed tokens may be used");
        _;
    }

    modifier onlyCollateralToken(IERC20 token_) {
        require(isCollateralToken(token_), "MarginApproved: Only collateral tokens may be used");
        _;
    }

    modifier onlyBorrowedToken(IERC20 token_) {
        require(isBorrowedToken(token_), "MarginApproved: Only borrowed tokens may be used");
        _;
    }

    // Add a collateral token
    function addCollateralToken(IERC20[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!_collateralTokens[token_[i]]) {
                _collateralTokens[token_[i]] = true;
                emit AddCollateralToken(token_[i]);
            }
        }
    }

    // Add a borrowed token
    function addBorrowedToken(IERC20[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!_borrowedTokens[token_[i]]) {
                _borrowedTokens[token_[i]] = true;
                emit AddBorrowedToken(token_[i]);
            }
        }
    }

    // Approve a token for collateral
    function setApprovedCollateralToken(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isCollateralToken(token_[i])) _approvedCollateralTokens[token_[i]] = approved_[i];
        }
    }

    // Approve a token to be used for borrowing
    function setApprovedBorrowedToken(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isBorrowedToken(token_[i])) _approvedBorrowedTokens[token_[i]] = approved_[i];
        }
    }

    // Check if a token is a collateral token
    function isCollateralToken(IERC20 token_) public view returns (bool) {
        return _collateralTokens[token_];
    }

    // Check if a token is a borrowed token
    function isBorrowedToken(IERC20 token_) public view returns (bool) {
        return _borrowedTokens[token_];
    }

    // Check if a token is an approved collateral token
    function isApprovedCollateralToken(IERC20 token_) public view returns (bool) {
        return isCollateralToken(token_) && _approvedCollateralTokens[token_];
    }

    // Check if a token is an approved borrowed token
    function isApprovedBorrowedToken(IERC20 token_) public view returns (bool) {
        return isBorrowedToken(token_) && _approvedBorrowedTokens[token_];
    }

    event AddCollateralToken(IERC20 token);
    event AddBorrowedToken(IERC20 token);
}
