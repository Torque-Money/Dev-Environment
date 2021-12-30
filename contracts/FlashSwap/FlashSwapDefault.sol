//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IFlashSwap.sol";
import "../lib/UniswapV2Router02.sol";
import "../LPool/LPool.sol";

contract FlashSwapDefault is IFlashSwap, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    UniswapV2Router02 public router; 
    LPool public pool;

    constructor(UniswapV2Router02 router_, LPool pool_) {
        router = router_;
        pool = pool_;
    }

    // Set the router to be used for the swap
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }

    // Set the pool
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }

    // Callback for swapping from one asset to another and return the amount of the asset swapped out for
    function flashSwap(
        address,
        IERC20[] memory tokenIn_, uint256[] memory amountIn_, IERC20 tokenOut_,
        uint256, bytes calldata
    ) external override returns (uint256) {
        address[] memory path = new address[](2);
        bool tokenOutIsLP = pool.isLPToken(tokenOut_);

        uint256 amountOut = 0;

        for (uint i = 0; i < tokenIn_.length; i++) {
            if (pool.isLPToken(tokenIn_[i])) {
                amountIn_[i] = pool.redeem(tokenIn_[i], amountIn_[i]);
                path[0] = address(pool.tokenFromLPToken(tokenIn_[i]));
            } else {
                path[0] = address(tokenIn_[i]);
            }

            if (tokenOutIsLP) {
                path[1] = address(pool.tokenFromLPToken(tokenOut_));
            } else {
                path[1] = address(tokenOut_);
            }

            if (path[0] == path[1]) {
                amountOut = amountOut.add(amountIn_[i]);
            } else {
                IERC20(path[0]).safeApprove(address(router), amountIn_[i]);
                amountOut = amountOut.add(router.swapExactTokensForTokens(amountIn_[i], 0, path, address(this), block.timestamp + 1 hours)[1]);
            }
        }

        if (tokenOutIsLP) {
            amountOut = pool.stake(IERC20(path[1]), amountOut);
        }

        tokenOut_.safeTransfer(_msgSender(), amountOut);

        return amountOut;
    }
}