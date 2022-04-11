//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {LPoolLiquidity} from "./LPoolLiquidity.sol";
import {LPoolToken} from "./Token/LPoolToken.sol";

abstract contract LPoolProvide is LPoolLiquidity {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Return the amount of LP tokens received for adding a given amount of tokens as liquidity
    function provideLiquidityOutLPTokens(address token_, uint256 amount_) public view onlyApprovedPT(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(LPFromPT(token_));

        uint256 _totalSupply = LPToken.totalSupply();
        uint256 _totalAmountLocked = totalAmountLocked(token_);

        if (_totalAmountLocked == 0) return amount_;

        return amount_.mul(_totalSupply).div(_totalAmountLocked);
    }

    // Provide tokens to the liquidity pool and receive LP tokens that represent the users share in the pool
    function provideLiquidity(address token_, uint256 amount_) external whenNotPaused onlyApprovedPT(token_) returns (uint256) {
        require(amount_ > 0, "LPoolProvide: Amount of tokens must be greater than 0");

        LPoolToken LPToken = LPoolToken(LPFromPT(token_));

        uint256 outTokens = provideLiquidityOutLPTokens(token_, amount_);
        require(outTokens > 0, "LPoolProvide: Not enough tokens provided");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        LPToken.mint(_msgSender(), outTokens);

        emit AddLiquidity(_msgSender(), token_, amount_, outTokens);

        return outTokens;
    }

    // Get the amount of pool tokens for redeeming LP tokens
    function redeemLiquidityOutPoolTokens(address token_, uint256 amount_) public view onlyLP(token_) returns (uint256) {
        LPoolToken LPToken = LPoolToken(token_);

        uint256 _totalSupply = LPToken.totalSupply();
        uint256 _totalAmountLocked = totalAmountLocked(PTFromLP(token_));

        return amount_.mul(_totalAmountLocked).div(_totalSupply);
    }

    // Redeem LP tokens for the underlying asset
    function redeemLiquidity(address token_, uint256 amount_) external whenNotPaused onlyLP(token_) returns (uint256) {
        require(amount_ > 0, "LPoolProvide: Amount of tokens must be greater than 0");

        LPoolToken LPToken = LPoolToken(token_);
        address poolToken = PTFromLP(token_);

        uint256 outTokens = redeemLiquidityOutPoolTokens(token_, amount_);
        require(outTokens <= liquidity(poolToken), "LPoolProvide: Not enough liquidity to redeem at this time");

        LPToken.burn(_msgSender(), amount_);
        IERC20Upgradeable(poolToken).safeTransfer(_msgSender(), outTokens);

        emit RedeemLiquidity(_msgSender(), token_, amount_, outTokens);

        return outTokens;
    }

    event AddLiquidity(address indexed account, address token, uint256 amount, uint256 lpTokenAmount);
    event RedeemLiquidity(address indexed account, address token, uint256 amount, uint256 poolTokenAmount);
}
