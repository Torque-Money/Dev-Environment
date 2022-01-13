//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConverter {
    function swapMaxOut(
        IERC20 tokenIn_,
        uint256 amountIn_,
        IERC20 tokenOut_
    ) external returns (uint256);
}
