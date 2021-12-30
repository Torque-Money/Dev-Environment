//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashSwap.sol";
import "../lib/UniswapV2Router02.sol";

contract FlashSwapDefault is IFlashSwap, Ownable {
    UniswapV2Router02 public router; 

    constructor(UniswapV2Router02 router_) {
        router = router_;
    }

    // Set the router to be used for the swap
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }

    // Callback for swapping from one asset to another and return the amount of the asset swapped out for
    function flashSwap(
        address initiator_, IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_, uint256 minAmountOut_, bytes calldata data_
    ) external returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);

        address router = address(oracle.router());
        _token1.safeApprove(address(router), _amount);
        return UniswapV2Router02(router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 1 hours)[1];
    }
}