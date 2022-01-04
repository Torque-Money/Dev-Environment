//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolClaim.sol";
import "./LPoolDeposit.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Return the total value locked of a given asset
    function tvl(IERC20 token_) public view returns (uint256) {
        return token_.balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(IERC20 token_) public view override returns (uint256) {
        uint256 claimed = totalClaimed(token_);
        return tvl(token_).sub(claimed);
    }
}