//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolLiquidity.sol";
import "./LPoolToken.sol";

abstract contract LPoolStake is LPoolLiquidity {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Return the amount of tokens received for staking a given amount of tokens
    function stakeValue(IERC20 token_, uint256 amount_) public view returns (uint256) {
        LPoolToken LPToken = LPoolToken(address(LPFromPA(token_)));
        uint256 totalSupply = LPToken.totalSupply();
        uint256 totalValue = tvl(token_);
        return amount_.mul(totalSupply).div(totalValue);
    }

    // Stake tokens and receive LP tokens that represent the users share in the pool
    function stake(IERC20 token_, uint256 amount_) external onlyPA(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(address(LPFromPA(token_)));

        uint256 value = stakeValue(token_, amount_);
        require(value > 0, "Not enough tokens staked");

        token_.safeTransferFrom(_msgSender(), address(this), amount_);
        LPToken.mint(_msgSender(), value);

        emit Stake(_msgSender(), token_, amount_, value);

        return value;
    }

    // Get the value for redeeming LP tokens for the underlying asset
    function redeemValue(IERC20 token_, uint256 amount_) public view returns (uint256) {
        LPoolToken LPToken = LPoolToken(address(token_));
        uint256 totalSupply = LPToken.totalSupply();
        uint256 totalValue = tvl(token_);
        return amount_.mul(totalValue).div(totalSupply);
    }

    // Redeem LP tokens for the underlying asset
    function redeem(IERC20 token_, uint256 amount_) external onlyLP(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(address(token_));
        IERC20 approvedToken = PAFromLP(token_);

        uint256 value = redeemValue(LPToken, amount_);
        require(value <= liquidity(approvedToken), "Not enough liquidity to redeem at this time");

        LPToken.burn(_msgSender(), amount_);
        approvedToken.safeTransfer(_msgSender(), value);

        emit Redeem(_msgSender(), token_, amount_, value);

        return value;
    }

    event Stake(address indexed account, IERC20 token, uint256 amount, uint256 value);
    event Redeem(address indexed account, IERC20 token, uint256 amount, uint256 value);
}