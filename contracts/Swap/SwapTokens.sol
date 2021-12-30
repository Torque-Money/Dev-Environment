//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IFlashSwap.sol";
import "./SwapCore.sol";

abstract contract SwapAssets is SwapCore, ReentrancyGuard {
    using SafeMath for uint256;    
    using SafeERC20 for IERC20;

    // Swap one asset for another using an external function and allow the transaction as long as the minimum amount is satisfied - returns the amount of the asset out
    function flashSwap(
        IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_, uint256 minAmountOut_, ISwap flashSwap_, bytes calldata data_
    ) external returns (uint256) {
        tokenIn_.safeTransferFrom(_msgSender(), address(flashSwap_), amountIn_);

        uint256 amountOut = flashSwap_.flashSwap(_msgSender(), tokenIn_, amountIn_, tokenOut_, minAmountOut_, data_);
        require(amountOut >= minAmountOut_ && tokenOut_.balanceOf(address(this)) >= minAmountOut_, "Amount swapped is less than minimum amount out");

        tokenOut_.safeTransfer(_msgSender(), amountOut);
        emit FlashSwap(tokenIn_, amountIn_, tokenOut_, amountOut, flashSwap_, data_);

        return amountOut;
    }

    event FlashSwap(IERC20 tokenIn, uint256 amountIn, IERC20 tokenOut, uint256 amountOut, ISwap flashSwap, bytes data);
}