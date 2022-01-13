//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IFlashSwap.sol";

contract FlashSwap is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Swap a group of assets for another using an external function and allow the transaction as long as the minimum amount is satisfied - returns the amount of the asset out
    function flashSwap(
        IERC20[] memory tokenIn_,
        uint256[] memory amountIn_,
        IERC20[] memory tokenOut_,
        uint256[] memory minAmountOut_,
        IFlashSwap flashSwap_,
        bytes calldata data_
    ) external nonReentrant returns (uint256[] memory) {
        for (uint256 i = 0; i < tokenIn_.length; i++) {
            tokenIn_[i].safeTransferFrom(_msgSender(), address(flashSwap_), amountIn_[i]);
        }

        uint256[] memory amountOut = flashSwap_.flashSwap(_msgSender(), tokenIn_, amountIn_, tokenOut_, minAmountOut_, data_);
        for (uint256 i = 0; i < amountOut.length; i++) {
            require(amountOut[i] >= minAmountOut_[i] && tokenOut_[i].balanceOf(address(this)) >= minAmountOut_[i], "Amount swapped is less than minimum amount out");
            tokenOut_[i].safeTransfer(_msgSender(), amountOut[i]);
        }

        emit Swap(tokenIn_, amountIn_, tokenOut_, amountOut, flashSwap_, data_);

        return amountOut;
    }

    event Swap(IERC20[] tokenIn, uint256[] amountIn, IERC20[] tokenOut, uint256[] amountOut, IFlashSwap flashSwap, bytes data);
}
