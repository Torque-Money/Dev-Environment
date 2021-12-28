//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketLinkRouter.sol";
import "../lib/Median.sol";

abstract contract MarketLinkPrice is MarketLinkRouter {
    using SafeMath for uint256;
    using Median for uint256[];

    // Get the price between any 
    function pairPrice(
        IERC20 _token1, uint256 _amount, IERC20 _token2
    ) external view onlyApprovedOrLPToken(_token1) onlyApprovedOrLPToken(_token2) returns (uint256) {
        // First we need to check if we are dealing with a regular approved token or an LP token for both token1 and token2
    }
}