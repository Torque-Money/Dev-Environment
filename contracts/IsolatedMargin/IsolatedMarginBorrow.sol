//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsolatedMarginLevel.sol";

abstract contract IsolatedMarginBorrow is IsolatedMarginLevel {
    using SafeMath for uint256;

    uint256 public minCollateral; // **** Maybe this should go deeper too like make it so that you cant withdraw less than the collateral if borrowing

    // Set the minimum account collateral required to borrow against
    function setMinCollateral(uint256 minCollateral_) external onlyOwner {
        minCollateral = minCollateral_;
    }

    
}