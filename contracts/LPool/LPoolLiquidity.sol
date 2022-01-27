//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolClaim.sol";
import "./LPoolDeposit.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit {
    using SafeMath for uint256;

    // Return the total value locked of a given asset
    function tvl(address token_) public view onlyPT(token_) returns (uint256) {
        return IERC20Upgradeable(token_).balanceOf(address(this));
    }

    // Get the available liquidity of the pool
    function liquidity(address token_) public view override(LPoolClaim, LPoolDeposit) onlyPT(token_) returns (uint256) {
        uint256 claimed = totalClaimed(token_);

        return tvl(token_).sub(claimed);
    }

    // Get the total utilized in the pool
    function utilized(address token_) public view override(LPoolDeposit) onlyPT(token_) returns (uint256) {
        uint256 _liquidity = liquidity(token_);
        uint256 _tvl = tvl(token_);

        return _tvl.sub(_liquidity);
    }

    // Get the utilization rate for a given asset
    function utilizationRate(address token_) public view onlyPT(token_) returns (uint256, uint256) {
        uint256 _utilized = utilized(token_);
        uint256 _tvl = tvl(token_);

        return (_utilized, _tvl);
    }
}
