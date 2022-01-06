//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginAccount.sol";
import "./MarginApproved.sol";

abstract contract MarginBorrow is MarginAccount, MarginApproved {
    using SafeMath for uint256;

    uint256 public minCollateralPrice;

    constructor(uint256 minCollateralPrice_) {
        minCollateralPrice = minCollateralPrice_;
    }

    // Set the minimum collateral price
    function setMinCollateralPrice(uint256 minCollateralPrice_) external onlyOwner {
        minCollateralPrice = minCollateralPrice_;
    }

    // Borrow against the collateral
    function borrow(IERC20 borrowed_, uint256 amount_) external onlyApprovedBorrow(borrowed_) {
        require(collateralPrice(_msgSender()) >= minCollateralPrice, "Collateral price must be greater than minimum");

        if (!isBorrowing(borrowed_, _msgSender())) _setInitialBorrowBlock(borrowed_, block.number, _msgSender());

        pool.claim(borrowed_, amount_);
        _setBorrowed(borrowed_, borrowed(borrowed_, _msgSender()).add(amount_), _msgSender());

        uint256 _initialBorrowPrice = oracle.price(borrowed_, amount_);
        _setInitialBorrowPrice(borrowed_, initialBorrowPrice(borrowed_, _msgSender()).add(_initialBorrowPrice), _msgSender());

        emit Borrow(_msgSender(), borrowed_, amount_);
    }

    event Borrow(address indexed account, IERC20 borrowed, uint256 amount);
}
