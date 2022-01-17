//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConverter {
    function swapMaxOut(
        IERC20 tokenIn_,
        uint256 amountIn_,
        IERC20 tokenOut_
    ) external returns (uint256);

    function maxAmountOut(
        IERC20 tokenIn_,
        uint256 amountIn_,
        IERC20 tokenOut_
    ) external view returns (uint256);

    function minAmountIn(
        IERC20 tokenIn_,
        IERC20 tokenOut_,
        uint256 amountOut_
    ) external view returns (uint256);
}
