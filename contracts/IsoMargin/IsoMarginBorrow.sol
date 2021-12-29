//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginMargin.sol";

abstract contract IsoMarginBorrow is IsoMarginMargin {
    using SafeMath for uint256;

    mapping(IERC20 => uint256) private _minCollateral;

    // Set the minimum collateral required to borrow against
    function setMinCollateral(IERC20 token_, uint256 amount_) external onlyOwner {
        _minCollateral[token_] = amount_;
    }

    // Get the minimum collateral required to borrow against
    function minCollateral(IERC20 token_) public view returns (uint256) {
        return _minCollateral[token_];
    }

    // Allow a user to borrow against their collateral
    function borrow(IERC20 collateral_, IERC20 borrowed_, uint256 amount_) external onlyLPOrApprovedToken(collateral_) onlyApprovedToken(borrowed_) {
        require(amount_ >= minCollateral(collateral_), "Not enough collateral to support the minimum collateral requirement");
        require(collateral_ != borrowed_, "Cannot borrow against the same asset");

        if (borrowed(collateral_, borrowed_, _msgSender()) == 0) _setInitialBorrowBlock(collateral_, borrowed_, block.number);
        uint256 initialBorrowPrice = marketLink.swapPrice(borrowed_, amount_, collateral_);
        _setInitialBorrowPrice(collateral_, borrowed_, _initialBorrowPrice(collateral_, borrowed_).add(initialBorrowPrice));

        pool.claim(borrowed_, amount_);
        _setBorrowed(collateral_, borrowed_, borrowed(collateral_, borrowed_, _msgSender()).add(amount_));
        
        emit Borrow(_msgSender(), collateral_, borrowed_, amount_);
    }

    event Borrow(address indexed account, IERC20 collateral, IERC20 borrowed, uint256 amount);
}