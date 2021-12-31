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

    // The fee paid out to the liquidator for liquidating an undercollateralized account (x% of difference between threshold and undercollateralization level)
    function liquidationFee(IERC20 borrowed_, address account_) public view returns (uint256) {
        uint256 percentReward = minMarginLevel.mul(100).div(minMarginLevel.add(100)).div(2);
        return collateral(borrowed_, account_).mul(percentReward).div(100);
    }

    // Liquidate an undercollateralized account
    function liquidate(IERC20 borrowed_, address account_) external {
        require(underCollateralized(borrowed_, account_), "Only undercollateralized accounts may be liquidated");

        // **** It is not going to be this easy - I need to go and swap all of the collateral back again (also return them a fee after)

        uint256 accountCollateral = collateral(borrowed_, account_);
        uint256 fee = liquidationFee(collateral_, borrowed_, account_);
        accountCollateral = accountCollateral.sub(fee);
        collateral_.safeTransfer(_msgSender(), fee);

        uint256 swapAmount = _swap(collateral_, accountCollateral, borrowed_);
        pool.deposit(borrowed_, swapAmount);

        _setInitialBorrowPrice(collateral_, borrowed_, 0, account_);
        _setBorrowed(collateral_, borrowed_, 0, account_);
        _setCollateral(collateral_, borrowed_, 0, account_);

        emit Liquidated(account_, collateral_, borrowed_, accountCollateral, _msgSender(), fee);
    }

    event Liquidated(address indexed account, IERC20 collateral, IERC20 borrowed, uint256 amount, address liquidator, uint256 fee);
}