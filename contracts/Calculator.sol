//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ILPool.sol";

// **** It appears that the standard deployed contracts are factory and router, 

contract Calculator is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private router;
    address private lPool;

    constructor(address router_) {
        router = router_;
    }

    // **** Now I need some sort of way of getting the price with the oracle
    // **** I also need a way of hooking into the liquidity pool

    function poolTokenValue(address _token, uint256 _decimals) public returns (uint256 _value) {
        // Validate that the token is valid
        ILPool pool = ILPool(_token);
        require(pool.isPoolToken(_token), "Invalid pool token");
        address approvedAsset = pool.getApprovedAsset(_token);

        // Find how much approved asset each pool token is worth
        uint256 numerator = _decimals.mul(IERC20(approvedAsset).balanceOf(lPool));
        uint256 denominator = IERC20(_token).totalSupply();
        _value = numerator.div(denominator.add(1)); // Prevent division by 0 errors
    }

    function pairValue(address _token1, address _token2) public {
        // **** If the token is valued against one of the tokens from the pool we will value it against its respective pair and use that maths
        UniswapV2Router02(router).getAmountsOut(amountIn, path);
    }

    // ======== Setters ========

    function setRouterAddress(address _router) public onlyOwner {
        router = _router;
    }
}