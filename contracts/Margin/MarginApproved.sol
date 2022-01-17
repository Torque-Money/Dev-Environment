//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(IERC20 => bool) private _approvedCollateral;
    mapping(IERC20 => bool) private _approvedBorrowed;

    modifier onlyApprovedCollateral(IERC20 token_) {
        require(isApprovedCollateral(token_), "MarginApproved: Only approved collateral tokens may be used");
        _;
    }

    modifier onlyApprovedBorrowed(IERC20 token_) {
        require(isApprovedBorrowed(token_), "MarginApproved: Only approved borrowed tokens may be used");
        _;
    }

    // Approve a token for collateral
    function setApprovedCollateral(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            _approvedCollateral[token_[i]] = approved_[i];
        }
    }

    // Approve a token to be used for borrowing
    function setApprovedBorrowed(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            _approvedBorrowed[token_[i]] = approved_[i];
        }
    }

    // Check if a token is approved
    function isApprovedCollateral(IERC20 token_) public view returns (bool) {
        return _approvedCollateral[token_];
    }

    // Check if a token is approved
    function isApprovedBorrowed(IERC20 token_) public view returns (bool) {
        return _approvedBorrowed[token_];
    }
}
