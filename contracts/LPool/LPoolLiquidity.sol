//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolClaim.sol";
import "./LPoolDeposit.sol";

import "hardhat/console.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit {
    using SafeMath for uint256;

    // Return the total value locked of a given asset
    function tvl(IERC20 token_) public view returns (uint256) {
        return token_.balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(IERC20 token_) public view override(LPoolClaim, LPoolDeposit) returns (uint256) {
        uint256 claimed = totalClaimed(token_);

        console.log(tvl(token_));
        console.log(claimed);

        return tvl(token_).sub(claimed);
    }

    // Get the total utilized in the pool
    function utilized(IERC20 token_) public view override(LPoolDeposit) returns (uint256) {
        uint256 _liquidity = liquidity(token_);
        uint256 _tvl = tvl(token_);
        return _tvl.sub(_liquidity);
    }

    // Get the utilization rate for a given asset
    function utilizationRate(IERC20 token_) public view returns (uint256, uint256) {
        uint256 _tvl = tvl(token_);
        uint256 _utilized = utilized(token_);
        return (_utilized, _tvl);
    }
}
