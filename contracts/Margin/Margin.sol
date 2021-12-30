//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Oracle/Oracle.sol";
import "../FlashSwap/FlashSwap.sol";
import "../FlashSwap/IFlashSwap.sol";
import "../LPool/LPool.sol";

abstract contract Margin is Ownable {
    using SafeERC20 for IERC20;

    LPool public pool;
    Oracle public oracle;
    FlashSwap public flashSwap;

    IFlashSwap public defaultFlashSwap;

    constructor(LPool pool_, Oracle oracle_, FlashSwap flashSwap_, IFlashSwap defaultFlashSwap_) {
        pool = pool_;
        oracle = oracle_;
        flashSwap = flashSwap_;
        defaultFlashSwap = defaultFlashSwap_;
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

    // Set the default flash swap to use
    function setDefaultFlashSwap(IFlashSwap flashSwap_) external onlyOwner {
        defaultFlashSwap = flashSwap_;
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

    // Approve the flash swap to use tokens and execute swap
    function _flashSwap(IERC20[] memory tokenIn_, uint256[] memory amountIn_, IERC20 tokenOut_, uint256 minAmountOut_, IFlashSwap flashSwap_, bytes calldata data_) internal returns (uint256) {
        for (uint i = 0; i < tokenIn_.length; i++) {
            tokenIn_[i].safeApprove(address(flashSwap), amountIn_[i]);
        }
        return flashSwap.flashSwap(tokenIn_, amountIn_, tokenOut_, minAmountOut_, flashSwap_, data_);
    }

    // Execute the flash swap with the default flash swap
    function _flashSwap(IERC20[] memory tokenIn_, uint256[] memory amountIn_, IERC20 tokenOut_, uint256 minAmountOut_, bytes calldata data_) internal returns (uint256) {
        return _flashSwap(tokenIn_, amountIn_, tokenOut_, minAmountOut_, defaultFlashSwap, data_);
    }
}