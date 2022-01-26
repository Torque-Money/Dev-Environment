//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../lib/UniswapV2Router02.sol";
import "./IConverter.sol";

contract Converter is IConverter, Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    UniswapV2Router02 public router;

    constructor(UniswapV2Router02 router_) {
        router = router_;
    }

    // Set the router to be used
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }

    // Swap the given amount for the maximum tokens out
    function swapMaxTokenOut(
        IERC20Upgradeable tokenIn_,
        uint256 amountIn_,
        IERC20Upgradeable tokenOut_
    ) external override returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn_);
        path[1] = router.WETH();
        path[2] = address(tokenOut_);

        tokenIn_.safeTransferFrom(_msgSender(), address(this), amountIn_);
        tokenIn_.safeApprove(address(router), amountIn_);
        uint256 amountOut = router.swapExactTokensForTokens(amountIn_, 0, path, _msgSender(), block.timestamp + 1)[1];

        return amountOut;
    }

    // Get the maximum output tokens for given input tokens
    function maxAmountTokenOut(
        IERC20Upgradeable tokenIn_,
        uint256 amountIn_,
        IERC20Upgradeable tokenOut_
    ) external view override returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn_);
        path[1] = router.WETH();
        path[2] = address(tokenOut_);

        uint256 amountOut = router.getAmountsOut(amountIn_, path)[1];
        return amountOut;
    }

    // Get the minimum input tokens required for the given output tokens
    function minAmountTokenInTokenOut(
        IERC20Upgradeable tokenIn_,
        IERC20Upgradeable tokenOut_,
        uint256 amountOut_
    ) external view override returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn_);
        path[1] = router.WETH();
        path[2] = address(tokenOut_);

        uint256 amountIn = router.getAmountsIn(amountOut_, path)[0];
        return amountIn;
    }

    // Swap the given amount for the maximum ETH out
    function swapMaxEthOut(IERC20Upgradeable tokenIn_, uint256 amountIn_) external override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(router.WETH());

        tokenIn_.safeTransferFrom(_msgSender(), address(this), amountIn_);
        tokenIn_.safeApprove(address(router), amountIn_);
        uint256 amountOut = router.swapExactTokensForETH(amountIn_, 0, path, _msgSender(), block.timestamp + 1)[1];

        return amountOut;
    }

    // Get the maximum output eth for given input tokens
    function maxAmountEthOut(IERC20Upgradeable tokenIn_, uint256 amountIn_) external view override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = router.WETH();

        uint256 amountOut = router.getAmountsOut(amountIn_, path)[1];
        return amountOut;
    }

    // Get the minimum input tokens for required output eth
    function minAmountTokenInEthOut(IERC20Upgradeable tokenIn_, uint256 amountOut_) external view override returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = router.WETH();

        uint256 amountIn = router.getAmountsIn(amountOut_, path)[0];
        return amountIn;
    }
}
