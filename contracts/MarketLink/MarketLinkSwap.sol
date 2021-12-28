//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MarketLinkRouter.sol";

abstract contract MarketLinkSwap is MarketLinkRouter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Swap between an LP token or regular token with another LP token or regular token
    function swap(IERC20 _tokenIn, uint256 _amountIn, IERC20 _tokenOut) external returns (uint256) {
        _tokenIn.safeTransferFrom(_msgSender(), address(this), _amountIn);

        address[] memory path = new address[](2);

        if (pool.isLPToken(_tokenIn)) {
            _amountIn = pool.redeem(_tokenIn, _amountIn);
            path[0] = address(pool.tokenFromLPToken(_tokenIn));
        } else {
            path[0] = address(_tokenIn);
        }

        bool tokenOutIsLP = pool.isLPToken(_tokenOut);
        if (tokenOutIsLP) {
            path[1] = address(pool.tokenFromLPToken(_tokenOut));
        } else {
            path[1] = address(_tokenOut);
        }

        _tokenIn.safeApprove(address(router), _amountIn);
        uint256 swappedAmount = router.swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp + 1 hours)[1];

        if (tokenOutIsLP) {
            swappedAmount = pool.stake(IERC20(path[1]), swappedAmount);
        }

        _tokenOut.safeTransfer(_msgSender(), swappedAmount);

        emit Swap(_msgSender(), _tokenIn, _amountIn, _tokenOut, swappedAmount);

        return swappedAmount;
    }

    event Swap(address indexed account, IERC20 tokenIn, uint256 amountIn, IERC20 tokenOut, uint256 amountOut);
}