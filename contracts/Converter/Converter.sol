//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/UniswapV2Router02.sol";
import "./IConverter.sol";

contract Converter is IConverter, Ownable {
    using SafeERC20 for IERC20;

    UniswapV2Router02 public router;

    constructor(UniswapV2Router02 router_) {
        router = router_;
    }

    // Set the router to be used
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }

    // Swap the given amount for the maximum amount out
    function swapMaxOut(
        IERC20 tokenIn_,
        uint256 amountIn_,
        IERC20 tokenOut_
    ) external override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);

        tokenIn_.safeTransferFrom(_msgSender(), address(this), amountIn_);
        tokenIn_.safeApprove(address(router), amountIn_);
        uint256 amountOut = router.swapExactTokensForTokens(amountIn_, 0, path, _msgSender(), block.timestamp + 1)[1];

        return amountOut;
    }

    // Get the maximum output tokens for given input tokens
    function maxAmountOut(
        IERC20 tokenIn_,
        uint256 amountIn_,
        IERC20 tokenOut_
    ) external view override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);

        uint256 amountOut = router.getAmountsOut(amountIn_, path)[1];
        return amountOut;
    }

    // Get the minimum input tokens required for the given output tokens
    function minAmountIn(
        IERC20 tokenIn_,
        IERC20 tokenOut_,
        uint256 amountOut_
    ) external view override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);

        uint256 amountIn = router.getAmountsIn(amountOut_, path)[0];
        return amountIn;
    }
}
