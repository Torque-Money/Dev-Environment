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

    }

    // Liquidate an undercollateralized account
    function liquidate(IERC20 collateral_, IERC20 borrowed_, address account_) external {
        
    }

    event Liquidated();
}