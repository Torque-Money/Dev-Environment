//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IConverter {
    function swapMaxTokenOut(
        IERC20Upgradeable tokenIn_,
        uint256 amountIn_,
        IERC20Upgradeable tokenOut_
    ) external returns (uint256);

    function maxAmountTokenOut(
        IERC20Upgradeable tokenIn_,
        uint256 amountIn_,
        IERC20Upgradeable tokenOut_
    ) external view returns (uint256);

    function minAmountTokenInTokenOut(
        IERC20Upgradeable tokenIn_,
        IERC20Upgradeable tokenOut_,
        uint256 amountOut_
    ) external view returns (uint256);

    function swapMaxEthOut(IERC20Upgradeable tokenIn_, uint256 amountIn_) external returns (uint256);

    function maxAmountEthOut(IERC20Upgradeable tokenIn_, uint256 amountIn_) external view returns (uint256);

    function minAmountTokenInEthOut(IERC20Upgradeable tokenIn_, uint256 amountOut_) external view returns (uint256);
}
