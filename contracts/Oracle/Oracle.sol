//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/UniswapV2Router02.sol";

contract Oracle is Ownable {
    UniswapV2Router02 public router;
    IERC20 public priceToken;

    constructor(UniswapV2Router02 router_, IERC20 priceToken_) {
        router = router_;
        priceToken = priceToken_;
    }

    // Set the router to be used with the oracle
    function setRouter(UniswapV2Router02 router_) external onlyOwner {
        router = router_;
    }

    // Set the price token
    function setPriceToken(IERC20 priceToken_) external onlyOwner {
        priceToken = priceToken_;
    }

    // Get the price of an asset in terms of the price asset
    function price(IERC20 asset_, uint256 amount_) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(asset_);
        path[1] = address(priceToken);
        uint256 amountOut = router.getAmountsOut(amount_, path)[1];
        return amountOut;
    }

    // Get the amounts of an asset in exchange for the asset price
    function amount(uint256 amount_, IERC20 asset_) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(priceToken);
        path[1] = address(asset_);
        uint256 amountOut = router.getAmountsOut(amount_, path)[1];
        return amountOut;
    }
}
