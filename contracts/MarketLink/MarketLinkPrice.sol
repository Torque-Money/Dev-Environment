//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketLinkRouter.sol";

abstract contract MarketLinkPrice is MarketLinkRouter {
    using SafeMath for uint256;

    // Get the price between any 
    function swapPrice(
        IERC20 _token1, uint256 _amount, IERC20 _token2
    ) external view onlyApprovedOrLPToken(_token1) onlyApprovedOrLPToken(_token2) returns (uint256) {
        bool token1IsLP = pool.isLPToken(_token1);
        bool token2IsLP = pool.isLPToken(_token2);

        address[] memory pair = new address[](2);

        // **** Now we want to be able to get the prices of the converted tokens - if they are LP tokens then reconvert to the price in terms of them
    }
}