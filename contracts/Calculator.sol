//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

// **** It appears that the standard deployed contracts are factory and router, 

contract Calculator is Ownable {
    address private factory;
    address private router;

    constructor(address factory_, address router_) {
        factory = factory_;
        router = router_;
    }

    // **** Now I need some sort of way of getting the price with the oracle
    // **** I also need a way of hooking into the liquidity pool

    function valueTokenPair() public {
        UniswapV2Router02(router).getAmountsOut(amountIn, path);
    }

    function setFactoryAddress(address _factory) public onlyOwner {
        factory = _factory;
    }

    function setRouterAddress(address _router) public onlyOwner {
        router = _router;
    }
}