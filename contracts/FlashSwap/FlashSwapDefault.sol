//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/UniswapV2Router02.sol";
import "../LPool/LPool.sol";
import "../lib/Set.sol";
import "./IFlashSwap.sol";

contract FlashSwapDefault is IFlashSwap, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using TokenSet for TokenSet.Set;

    UniswapV2Router02 public router; 
    LPool public pool;

    mapping(uint256 => TokenSet.Set) private _sets;
    mapping(uint256 => mapping(IERC20 => uint256)) private _amounts;
    uint256 private _index;

    constructor(UniswapV2Router02 router_, LPool pool_) {
        router = router_;
        pool = pool_;
    }

    // Set the router to be used for the swap
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }

    // Set the pool
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }

    function _bytesToAddress(bytes memory source_) internal pure returns (address addr) {
        assembly {
            addr := mload(add(source_, 0x14))
        }
    }

    // Wrapper for the swap
    function _flashSwap(IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_) internal returns (uint256) {
        address[] memory path = new address[](2);
        bool tokenOutIsLP = pool.isLP(tokenOut_);
        uint256 amountOut = 0;

        if (pool.isLP(tokenIn_)) {
            amountIn_ = pool.redeem(tokenIn_, amountIn_);
            path[0] = address(pool.PAFromLP(tokenIn_));

        } else {
            path[0] = address(tokenIn_);
        }

        if (tokenOutIsLP) {
            path[1] = address(pool.PAFromLP(tokenOut_));

        } else {
            path[1] = address(tokenOut_);
        }

        if (path[0] == path[1]) {
            amountOut = amountOut.add(amountIn_);

        } else {
            IERC20(path[0]).safeApprove(address(router), amountIn_);
            amountOut = amountOut.add(router.swapExactTokensForTokens(amountIn_, 0, path, address(this), block.timestamp + 1 hours)[1]);
        }

        if (tokenOutIsLP) amountOut = pool.stake(IERC20(path[1]), amountOut);

        tokenOut_.safeTransfer(_msgSender(), amountOut);

        return amountOut;
    }

    // Wrapper for the amounts out
    function _amountsIn(IERC20 tokenIn_, uint256 minAmountOut_, IERC20 tokenOut_) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);
        return router.getAmountsIn(minAmountOut_, path)[0];
    }

    function _amountsOut(IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn_);
        path[1] = address(tokenOut_);
        return router.getAmountsOut(amountIn_, path)[0];
    }

    // Callback for swapping from one asset to another and return the amount of the asset swapped out for
    function flashSwap(
        address,
        IERC20[] memory tokenIn_, uint256[] memory amountIn_, IERC20[] memory tokenOut_,
        uint256[] memory minAmountOut_, bytes memory data_
    ) external override returns (uint256[] memory) {
        // Get indexes for in and out storages
        uint256 inIndex = _index++;
        uint256 outIndex = _index++;
        uint256 finalIndex = _index++;

        // Move in tokens and amounts to a set and a mapping
        TokenSet.Set storage inSet = _sets[inIndex];
        mapping(IERC20 => uint256) storage inAmounts = _amounts[inIndex];
        for (uint i = 0; i < tokenIn_.length; i++) {
            IERC20 token = tokenIn_[i];
            inSet.insert(token);
            inAmounts[token] = amountIn_[i];
        }

        // Move out tokens and amounts to a set and a mapping
        TokenSet.Set storage outSet = _sets[outIndex];
        mapping(IERC20 => uint256) storage outAmounts = _amounts[outIndex];
        for (uint i = 0; i < tokenOut_.length; i++) {
            IERC20 token = tokenOut_[i];
            outSet.insert(token);
            outAmounts[token] = minAmountOut_[i];
        }

        mapping(IERC20 => uint256) storage finalAmounts = _amounts[finalIndex];

        for (uint i = 0; i < outSet.count(); i++) {
            IERC20 outToken = outSet.keyAtIndex(i);
            uint256 minAmountOut = outAmounts[outToken]; // **** Careful of overflows

            for (uint j = 0; j < inSet.count(); j++) {
                IERC20 inToken = inSet.keyAtIndex(j);
                uint256 amountIn = inAmounts[inToken];

                uint256 minIn = _amountsIn(inToken, minAmountOut, outToken);
                if (minIn >= amountIn) {
                    uint256 out = _flashSwap(inToken, amountIn, outToken);

                    finalAmounts[outToken] = finalAmounts[outToken].add(out);

                    inSet.remove(inToken);

                    if (out >= minAmountOut) break;
                    else minAmountOut = minAmountOut.sub(out);

                } else {
                    uint256 out = _flashSwap(inToken, minIn, outToken);

                    finalAmounts[outToken] = finalAmounts[outToken].add(out);

                    break;
                }
            }
        }

        uint256[] memory amountsOut = new uint256[](tokenOut_.length);
        for (uint i = 0; i < amountsOut.length; i++) {
            amountsOut[i] = finalAmounts[tokenOut_[i]];
        }

        // **** Look into a better way of getting the correct amount out too

        return amountsOut;
    }
}