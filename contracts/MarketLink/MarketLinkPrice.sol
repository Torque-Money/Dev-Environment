//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketLinkRouter.sol";

abstract contract MarketLinkPrice is MarketLinkRouter {
    // Get the price between an LP token or regular token and another LP token or regular token
    function swapPrice(IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_) external view returns (uint256) {
        address[] memory path = new address[](2);

        if (pool.isLPToken(tokenIn_)) {
            amountIn_ = pool.redeemValue(tokenIn_, amountIn_);
            path[0] = address(pool.tokenFromLPToken(tokenIn_));
        } else {
            path[0] = address(tokenIn_);
        }

        bool tokenOutIsLP = pool.isLPToken(tokenOut_);
        if (tokenOutIsLP) {
            path[1] = address(pool.tokenFromLPToken(tokenOut_));
        } else {
            path[1] = address(tokenOut_);
        }

        uint256 swappedAmount;
        if (path[0] == path[1]) {
            swappedAmount = amountIn_;
        } else {
            swappedAmount = router.getAmountsOut(amountIn_, path)[1];
        }

        if (tokenOutIsLP) {
            swappedAmount = pool.stakeValue(IERC20(path[1]), swappedAmount);
        }

        return swappedAmount;
    }
}