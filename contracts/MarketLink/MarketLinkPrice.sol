//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketLinkRouter.sol";

abstract contract MarketLinkPrice is MarketLinkRouter {
    // Get the price between an LP token or regular token and another LP token or regular token
    function swapPrice(IERC20 _tokenIn, uint256 _amountIn, IERC20 _tokenOut) external view returns (uint256) {
        address[] memory path = new address[](2);

        if (pool.isLPToken(_tokenIn)) {
            _amountIn = pool.redeemValue(_tokenIn, _amountIn);
            path[0] = address(pool.tokenFromLPToken(_tokenIn));
        } else {
            path[0] = address(_tokenIn);
        }

        bool tokenOutIsLP = pool.isLPToken(_tokenOut);
        if (tokenOutIsLP) {
            path[1] = address(pool.tokenFromLPToken(_tokenOut));
        } else {
            path[1] = address(_tokenOut);
        }

        uint256 swappedAmount = router.getAmountsOut(_amountIn, path)[1];

        if (tokenOutIsLP) {
            swappedAmount = pool.stakeValue(IERC20(path[1]), swappedAmount);
        }

        return swappedAmount;
    }
}