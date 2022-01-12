//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Oracle/Oracle.sol";
import "../FlashSwap/FlashSwap.sol";
import "../FlashSwap/IFlashSwap.sol";
import "../LPool/LPool.sol";

abstract contract MarginCore is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    LPool public pool;
    Oracle public oracle;
    FlashSwap public flashSwap;

    constructor(
        LPool pool_,
        Oracle oracle_,
        FlashSwap flashSwap_
    ) {
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

    // Approve the flash swap to use tokens and execute swap
    function _flashSwap(
        IERC20[] memory tokenIn_,
        uint256[] memory amountIn_,
        IERC20[] memory tokenOut_,
        uint256[] memory minAmountOut_,
        IFlashSwap flashSwap_,
        bytes memory data_
    ) internal returns (uint256[] memory) {
        for (uint256 i = 0; i < tokenIn_.length; i++) tokenIn_[i].safeApprove(address(flashSwap), amountIn_[i]);
        return flashSwap.flashSwap(tokenIn_, amountIn_, tokenOut_, minAmountOut_, flashSwap_, data_);
    }
}
