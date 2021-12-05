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

    constructor(address router_, address lPool_) {
        router = router_;
        lPool = lPool_;
    }

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

    function pairValue(address _token1, address _token2, uint256 _decimals) public {
        // Update the path if the tokens are pool tokens
        address[] memory path = new uint256[](2);

        ILPool pool = ILPool(lPool);
        if (pool.isPoolToken(_token1)) {
            path[0] = pool.getApprovedAsset(_token1);
        } else {
            path[0] = _token1;
        }
        if (pool.isPoolToken(_token2)) {
            path[1] = pool.getApprovedAsset(_token2);
        } else {
            path[1] = _token2;
        }

        // Get the number of tokens2 earned from token1
        uint256[] value = UniswapV2Router02(router).getAmountsOut(_decimals, path)[1];
    }

    // ======== Setters ========

    function setRouterAddress(address _router) public onlyOwner {
        router = _router;
    }

    function setLPoolAddress(address _lPool) public onlyOwner {
        lPool = _lPool;
    }
}