//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./IsolatedMarginLevel.sol";

abstract contract IsolatedMarginLiquidate is IsolatedMarginLevel {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public liquidationFeePercent;

    constructor(uint256 liquidationFeePercent_) {
        liquidationFeePercent = liquidationFeePercent_;
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercent_) external onlyOwner {
        liquidationFeePercent = liquidationFeePercent_;
    }

    // Liquidate an undercollateralized account
    function liquidate(IERC20 borrowed_, address account_, IFlashSwap flashSwap_, bytes memory data_) external {
        require(underCollateralized(borrowed_, account_), "Only undercollateralized accounts may be liquidated");

        uint256 accountCollateral = collateral(borrowed_, account_);

        uint256 swapAmount = _swap(collateral_, accountCollateral, borrowed_);
        pool.deposit(borrowed_, swapAmount);

        _setInitialBorrowPrice(collateral_, borrowed_, 0, account_);
        _setBorrowed(collateral_, borrowed_, 0, account_);
        _setCollateral(collateral_, borrowed_, 0, account_);

        emit Liquidated(account_, collateral_, borrowed_, accountCollateral, _msgSender(), fee);
    }

    event Liquidated(address indexed account, IERC20 collateral, IERC20 borrowed, uint256 amount, address liquidator, uint256 fee);
}