//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MarketLink/MarketLink.sol";
import "../LPool/LPool.sol";

abstract contract IsoMarginCore is Ownable {
    using SafeERC20 for IERC20;

    LPool public pool;
    MarketLink public marketLink;

    constructor(LPool pool_, MarketLink marketLink_) {
        pool = pool_;
        marketLink = marketLink_;
    }

    // Set the pool to use
    function setPool(LPool _pool) external onlyOwner {
        pool = _pool;
    }

    // Set the market link to use
    function setMarketLink(MarketLink _marketLink) external onlyOwner {
        marketLink = _marketLink;
    }

    modifier onlyApprovedToken(IERC20 _token) {
        require(pool.isApprovedToken(_token), "Only approved tokens may be used");
        _;
    }

    modifier onlyLPToken(IERC20 _token) {
        require(pool.isLPToken(_token), "Only LP tokens may be used");
        _;
    }

    modifier onlyLPOrApprovedToken(IERC20 _token) {
        require(pool.isApprovedToken(_token) || pool.isLPToken(_token), "Only approved tokens or LP tokens may be used");
        _;
    }

    // Approve the market link to swap and swap between two assets
    function _swap(IERC20 _tokenIn, uint256 _amountIn, IERC20 _tokenOut) internal returns (uint256) {
        _tokenIn.safeApprove(address(marketLink), _amountIn);
        return marketLink.swap(_tokenIn, _amountIn, _tokenOut);
    }
}