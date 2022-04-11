//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {UniswapV2Router02} from "../lib/UniswapV2Router02.sol";
import {WETH} from "../lib/WETH.sol";

import {ConverterCore} from "./ConverterCore.sol";

abstract contract ConverterConvert is ConverterCore {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Helper for calculating token path
    function _tokenPath(address tokenIn_, address tokenOut_) internal view returns (address[] memory) {
        require(tokenIn_ != tokenOut_, "ConverterConvert: Tokens cannot be the same");

        address weth = UniswapV2Router02(router).WETH();

        address[] memory path;
        if (tokenIn_ == weth) {
            path = new address[](2);
            path[0] = weth;
            path[1] = tokenOut_;
        } else if (tokenOut_ == weth) {
            path = new address[](2);
            path[0] = tokenIn_;
            path[1] = weth;
        } else {
            path = new address[](3);
            path[0] = tokenIn_;
            path[1] = weth;
            path[2] = tokenOut_;
        }

        return path;
    }

    // Get the maximum output tokens for given input tokens
    function maxAmountTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) public view virtual returns (uint256) {
        address[] memory path = _tokenPath(tokenIn_, tokenOut_);

        uint256 amountOut = UniswapV2Router02(router).getAmountsOut(amountIn_, path)[path.length - 1];
        return amountOut;
    }

    // Get the minimum input tokens required for the given output tokens
    function minAmountTokenInTokenOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) public view virtual returns (uint256) {
        address[] memory path = _tokenPath(tokenIn_, tokenOut_);

        uint256 amountIn = UniswapV2Router02(router).getAmountsIn(amountOut_, path)[0];
        return amountIn;
    }

    // Helper to get the path for an input eth
    function _ethOutPath(address tokenIn_) internal view returns (bool, address[] memory) {
        address weth = UniswapV2Router02(router).WETH();

        address[] memory path;
        if (tokenIn_ == weth) return (true, path);
        else {
            path = new address[](2);
            path[0] = tokenIn_;
            path[1] = weth;

            return (false, path);
        }
    }

    // Helper to get the path for an output eth
    function _ethInPath(address tokenOut_) internal view returns (bool, address[] memory) {
        address weth = UniswapV2Router02(router).WETH();

        address[] memory path;
        if (tokenOut_ == weth) return (true, path);
        else {
            path = new address[](2);
            path[0] = weth;
            path[1] = tokenOut_;

            return (false, path);
        }
    }

    // Swap the given amount of tokens for the maximum tokens out
    function swapMaxTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) public virtual whenNotPaused returns (uint256) {
        address[] memory path = _tokenPath(tokenIn_, tokenOut_);

        IERC20Upgradeable(tokenIn_).safeTransferFrom(_msgSender(), address(this), amountIn_);
        IERC20Upgradeable(tokenIn_).safeApprove(router, amountIn_);
        uint256 amountOut = UniswapV2Router02(router).swapExactTokensForTokens(amountIn_, 0, path, _msgSender(), block.timestamp + 1)[path.length - 1];

        return amountOut;
    }

    // Swap the given amount of input eth for as many out tokens as possible
    function swapMaxEthInTokenOut(address tokenOut_) public payable virtual whenNotPaused returns (uint256) {
        (bool isWeth, address[] memory path) = _ethInPath(tokenOut_);

        if (isWeth) {
            address weth = UniswapV2Router02(router).WETH();
            WETH(weth).deposit{value: msg.value}();
            IERC20Upgradeable(weth).safeTransfer(_msgSender(), msg.value);

            return msg.value;
        } else return UniswapV2Router02(router).swapExactETHForTokens{value: msg.value}(0, path, _msgSender(), block.timestamp + 1)[path.length - 1];
    }

    // Swap the given amount for the maximum ETH out
    function swapMaxTokenInEthOut(address tokenIn_, uint256 amountIn_) public virtual whenNotPaused returns (uint256) {
        (bool isWeth, address[] memory path) = _ethOutPath(tokenIn_);

        IERC20Upgradeable(tokenIn_).safeTransferFrom(_msgSender(), address(this), amountIn_);

        if (isWeth) {
            address weth = UniswapV2Router02(router).WETH();
            WETH(weth).withdraw(amountIn_);

            (bool success, ) = _msgSender().call{value: amountIn_}(new bytes(0));
            require(success, "ConverterConvert: Failed to transfer ETH to caller. Make sure contract accepts payment");

            return amountIn_;
        } else {
            IERC20Upgradeable(tokenIn_).safeApprove(router, amountIn_);
            return UniswapV2Router02(router).swapExactTokensForETH(amountIn_, 0, path, _msgSender(), block.timestamp + 1)[path.length - 1];
        }
    }
}
