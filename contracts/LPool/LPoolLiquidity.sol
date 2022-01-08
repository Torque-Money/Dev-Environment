//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolClaim.sol";
import "./LPoolDeposit.sol";
import "./LPoolLend.sol";

abstract contract LPoolLiquidity is LPoolClaim, LPoolDeposit, LPoolLend {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Return the total value locked of a given asset
    function tvl(IERC20 token_) public view returns (uint256) {
        uint256 _loaned = totalLoaned(token_);
        return token_.balanceOf(address(this)).add(_loaned);
    }

    // Get the available liquidity of the pool
    function liquidity(IERC20 token_) public view override(LPoolClaim, LPoolDeposit, LPoolLend) returns (uint256) {
        uint256 claimed = totalClaimed(token_);
        uint256 _loaned = totalLoaned(token_);
        return tvl(token_).sub(claimed).sub(_loaned);
    }

    // Get the utilization rate for a given asset
    function utilizationRate(IERC20 token_) public view returns (uint256, uint256) {
        uint256 _liquidity = liquidity(token_);
        uint256 _tvl = tvl(token_);
        return (_tvl.sub(_liquidity), _tvl);
    }
}
