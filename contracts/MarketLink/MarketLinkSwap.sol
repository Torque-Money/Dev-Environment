//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MarketLinkRouter.sol";

abstract contract MarketLinkSwap is MarketLinkRouter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Swap between an LP token or regular token with another LP token or regular token
    function swap(IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_) external returns (uint256) {
        tokenIn_.safeTransferFrom(_msgSender(), address(this), amountIn_);

        address[] memory path = new address[](2);

        if (pool.isLPToken(tokenIn_)) {
            amountIn_ = pool.redeem(tokenIn_, amountIn_);
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

        uint256 amountOut;
        if (path[0] == path[1]) {
            amountOut = amountIn_;
        } else {
            IERC20(path[0]).safeApprove(address(router), amountIn_);
            amountOut = router.swapExactTokensForTokens(amountIn_, 0, path, address(this), block.timestamp + 1 hours)[1];
        }

        if (tokenOutIsLP) {
            amountOut = pool.stake(IERC20(path[1]), amountOut);
        }

        tokenOut_.safeTransfer(_msgSender(), amountOut);

        emit Swap(_msgSender(), tokenIn_, amountIn_, tokenOut_, amountOut);

        return amountOut;
    }

    event Swap(address indexed account, IERC20 tokenIn, uint256 amountIn, IERC20 tokenOut, uint256 amountOut);
}