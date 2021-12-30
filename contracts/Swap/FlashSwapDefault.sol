//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IFlashSwap.sol";
import "../lib/UniswapV2Router02.sol";

contract FlashSwapDefault is IFlashSwap, Ownable {
    using SafeERC20 for IERC20;

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
        address, IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_, uint256 minAmountOut_, bytes calldata
    ) external override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);

        tokenIn_.safeApprove(address(router), amountIn_);
        return router.swapExactTokensForTokens(amountIn_, 0, path, _msgSender(), block.timestamp + 1 hours)[1];

        // **** I NEED TO ADD THE OTHER STUFF IN AS WELL INCLUDING THE LP TOKENS
    }
}