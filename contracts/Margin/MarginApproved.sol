//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginCore.sol";

abstract contract MarginApproved is MarginCore {
    mapping(IERC20 => bool) private _approvedCollateral;
    mapping(IERC20 => bool) private _approvedBorrow;

    modifier onlyApprovedCollateral(IERC20 token_) {
        require(isApprovedCollateral(token_), "Only approved tokens may be used");
        _;
    }

    modifier onlyApprovedBorrow(IERC20 token_) {
        require(isApprovedBorrow(token_), "Only approved tokens may be used");
        _;
    }

    // Approve a token for collateral
    function setApprovedCollateral(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isApprovedCollateral(token_[i]) != approved_[i]) {
                _approvedCollateral[token_[i]] = approved_[i];
                emit ApproveCollateral(token_[i], approved_[i]);
            }
        }
    }

    // Approve a token to be used for borrowing
    function setApprovedBorrow(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isApprovedBorrow(token_[i]) != approved_[i]) {
                _approvedBorrow[token_[i]] = approved_[i];
                emit ApproveBorrow(token_[i], approved_[i]);
            }
        }
    }

    // Check if a token is approved
    function isApprovedCollateral(IERC20 token_) public view returns (bool) {
        return _approvedCollateral[token_];
    }

    // Check if a token is approved
    function isApprovedBorrow(IERC20 token_) public view returns (bool) {
        return _approvedBorrow[token_];
    }

    event ApproveCollateral(IERC20 token, bool approved);
    event ApproveBorrow(IERC20 token, bool approved);
}
