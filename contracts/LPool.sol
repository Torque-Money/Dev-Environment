//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/LPool/LPoolCore.sol";
import "./Margin.sol";

contract LPool is LPoolCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(uint256 periodLength_, uint256 cooldownLength_, uint256 taxPercent_) LPoolCore(periodLength_, cooldownLength_) {
    }


}