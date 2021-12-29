//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IsoMarginMargin.sol";

abstract contract IsoMarginRepay is IsoMarginMargin {
    function collateralAfterRepay() public view returns (uint256) {
        
    }

    function _repayGreater() internal {

    }

    function _repayLessOrEqual() internal {

    }
}