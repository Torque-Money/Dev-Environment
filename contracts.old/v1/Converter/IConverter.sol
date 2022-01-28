//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IConverter {
    function swapMaxTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external returns (uint256);

    function maxAmountTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) external view returns (uint256);

    function minAmountTokenInTokenOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external view returns (uint256);

    function swapMaxEthOut(address tokenIn_, uint256 amountIn_) external returns (uint256);

    function maxAmountEthOut(address tokenIn_, uint256 amountIn_) external view returns (uint256);

    function minAmountTokenInEthOut(address tokenIn_, uint256 amountOut_) external view returns (uint256);
}
