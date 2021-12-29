//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginRepay.sol";

abstract contract IsoMarginLiquidate is IsoMarginRepay {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Get the fee for liquidating an undercollateralized account
    function liquidationFee(IERC20 collateral_, IERC20 borrowed_, address account_) public view returns (uint256) {
        uint256 percentReward = minMarginLevel.mul(100).div(minMarginLevel.add(100));
        return collateral(collateral_, borrowed_, account_).mul(percentReward).div(100);
    }

    // Liquidate an undercollateralized account
    function liquidate(IERC20 collateral_, IERC20 borrowed_, address account_) external {
        // **** Should be robust enough to deal with even TRULY undercollateralized loans
    }

    event Liquidated(address indexed account, IERC20 collateral, IERC20 borrowed, uint256 amount, address liquidator, uint256 fee);
}