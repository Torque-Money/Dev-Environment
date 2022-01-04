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

    // Callback for swapping from one asset to another and return the amount of the asset swapped out for
    function flashSwap(
        address,
        IERC20[] memory tokenIn_, uint256[] memory amountIn_, IERC20[] memory tokenOut_,
        uint256[] memory minAmountOut_, bytes memory data_
    ) external override returns (uint256[] memory) {
        uint256 inIndex = _index++;
        uint256 outIndex = _index++;

        TokenSet.Set storage inSet = _sets[inIndex];
        mapping(IERC20 => uint256) storage inAmounts = _amounts[inIndex];
        for (uint i = 0; i < tokenIn_.length; i++) {
            IERC20 token = tokenIn_[i];
            inSet.insert(token);
            inAmounts[token] = amountIn_[i];
        }

        TokenSet.Set storage outSet = _sets[outIndex];
        mapping(IERC20 => uint256) storage outAmounts = _amounts[inIndex];
        for (uint i = 0; i < tokenOut_.length; i++) {
            IERC20 token = tokenOut_[i];
            outSet.insert(token);
            outAmounts[token] = minAmountOut_[i];
        }

        // **** So now we need to iterate over all of the out tokens, and then we need to swap each collateral until the minimum amount is satisfied

        for (uint i = 0; i < outSet.count(); i++) {
            IERC20 outToken = outSet.keyAtIndex(i);
            uint256 minAmountOut = outAmounts[outToken]; // **** Careful of overflows

            address[] memory path = new address[](2);
            path[1] = address(outToken);

            for (uint j = 0; j < inSet.count(); j++) {
                IERC20 inToken = inSet.keyAtIndex(j);
                uint256 amountIn = inAmounts[inToken];

                path[0] = address(inToken);

                uint256 out = router.getAmountsOut(amountIn, path)[1];
                if (out > minAmountOut)
                    amountIn = minAmountOut.mul(amountIn).div(out); // **** Is there any way of rounding up to make sure we get more than necessary ?
                }
                out = router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp.add(1))[1]; // **** I'm thinking regarding this, I could probs do some magic with swaptokensforexact
                minAmountOut = minAmountOut.sub(out); // **** Careful of underflows

                // **** Check the swap price, if it is greater then we will only take necessary amount and break, otherwise remove it all - maybe make an internal for LP etc
            }
        }

        // address[] memory path = new address[](2);
        // bool tokenOutIsLP = pool.isLP(tokenOut_);
        // uint256 amountOut = 0;

        // for (uint i = 0; i < tokenIn_.length; i++) {
        //     if (pool.isLP(tokenIn_[i])) {
        //         amountIn_[i] = pool.redeem(tokenIn_[i], amountIn_[i]);
        //         path[0] = address(pool.PAFromLP(tokenIn_[i]));

        //     } else {
        //         path[0] = address(tokenIn_[i]);
        //     }

        //     if (tokenOutIsLP) {
        //         path[1] = address(pool.PAFromLP(tokenOut_));

        //     } else {
        //         path[1] = address(tokenOut_);
        //     }

        //     if (path[0] == path[1]) {
        //         amountOut = amountOut.add(amountIn_[i]);

        //     } else {
        //         IERC20(path[0]).safeApprove(address(router), amountIn_[i]);
        //         amountOut = amountOut.add(router.swapExactTokensForTokens(amountIn_[i], 0, path, address(this), block.timestamp + 1 hours)[1]);
        //     }
        // }

        // if (tokenOutIsLP) amountOut = pool.stake(IERC20(path[1]), amountOut);

        // address rewarded = _bytesToAddress(data_);
        // if (rewarded != _bytesToAddress("")) {
        //     tokenOut_.safeTransfer(rewarded, amountOut.sub(minTokenOut_));
        //     amountOut = minTokenOut_;
        // }

        // tokenOut_.safeTransfer(_msgSender(), amountOut);

        // return amountOut;
    }
}