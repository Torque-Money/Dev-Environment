//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Oracle/Oracle.sol";
import "../FlashSwap/FlashSwap.sol";
import "../LPool/LPool.sol";

abstract contract CrossMarginCore is Ownable {
    using SafeERC20 for IERC20;

    LPool public pool;
    Oracle public oracle;
    FlashSwap public flashSwap;

    constructor(LPool pool_, Oracle oracle_, FlashSwap flashSwap_) {
        pool = pool_;
        oracle = oracle_;
        flashSwap = flashSwap_;
    }

    // Set the pool to use
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }

    // Set the oracle to use
    function setOracle(Oracle oracle_) external onlyOwner {
        oracle = oracle_;
    }

    // Set the flash swap to use
    function setFlashSwap(FlashSwap flashSwap_) external onlyOwner {
        flashSwap = flashSwap_;
    }

    modifier onlyApprovedToken(IERC20 token_) {
        require(pool.isApprovedToken(token_), "Only approved tokens may be used");
        _;
    }

    modifier onlyLPToken(IERC20 token_) {
        require(pool.isLPToken(token_), "Only LP tokens may be used");
        _;
    }

    modifier onlyLPOrApprovedToken(IERC20 token_) {
        require(pool.isApprovedToken(token_) || pool.isLPToken(token_), "Only approved tokens or LP tokens may be used");
        _;
    }

    // Approve the flash swap to use tokens
    function _flashSwap(IERC20 tokenIn_, uint256 amountIn_, IERC20 tokenOut_) internal returns (uint256) {
        tokenIn_.safeApprove(address(swap), amountIn_);
        return flashSwap.flashSwap(tokenIn_, amountIn_, tokenOut_);
    }
}