//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IConverter {
    function maxAmountTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external view returns (uint256);

    function minAmountTokenInTokenOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external view returns (uint256);

    function swapMaxTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external returns (uint256);

    function swapMaxEthInTokenOut(address tokenOut_) external payable returns (uint256);

    function swapMaxTokenInEthOut(address tokenIn_, uint256 amountIn_) external returns (uint256);
}
