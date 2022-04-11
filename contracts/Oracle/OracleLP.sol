//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../LPool/LPool.sol";

import {OraclePrice} from "./OraclePrice.sol";

abstract contract OracleLP is OraclePrice {
    using SafeMathUpgradeable for uint256;

    // Check if a token is supported
    function isSupported(address token_) public view virtual returns (bool) {
        return isApproved(token_) || (LPool(pool).isLP(token_) && isApproved(LPool(pool).PTFromLP(token_)));
    }

    // Get the price for a given token or LP token amount at the lowest threshold by the oracle
    function priceMin(address token_, uint256 amount_) public view virtual override onlySupported(token_) returns (uint256) {
        if (isApproved(token_)) return OraclePrice.priceMin(token_, amount_);
        else {
            uint256 redeemAmount = LPool(pool).redeemLiquidityOutPoolTokens(token_, amount_);
            address poolToken = LPool(pool).PTFromLP(token_);

            return OraclePrice.priceMin(poolToken, redeemAmount);
        }
    }

    // Get the price for a given token or LP token amount at the highest threshold by the oracle
    function priceMax(address token_, uint256 amount_) public view virtual override onlySupported(token_) returns (uint256) {
        if (isApproved(token_)) return OraclePrice.priceMax(token_, amount_);
        else {
            uint256 redeemAmount = LPool(pool).redeemLiquidityOutPoolTokens(token_, amount_);
            address poolToken = LPool(pool).PTFromLP(token_);

            return OraclePrice.priceMax(poolToken, redeemAmount);
        }
    }

    // Get the amount for a given token or LP token price at the lowest threshold by the oracle
    function amountMin(address token_, uint256 price_) public view virtual override onlySupported(token_) returns (uint256) {
        if (isApproved(token_)) return OraclePrice.amountMin(token_, price_);
        else {
            address poolToken = LPool(pool).PTFromLP(token_);
            uint256 poolTokenAmount = OraclePrice.amountMin(poolToken, price_);

            return LPool(pool).provideLiquidityOutLPTokens(poolToken, poolTokenAmount);
        }
    }

    // Get the amount for a given token or LP token price at the highest threshold by the oracle
    function amountMax(address token_, uint256 price_) public view virtual override onlySupported(token_) returns (uint256) {
        if (isApproved(token_)) return OraclePrice.amountMax(token_, price_);
        else {
            address poolToken = LPool(pool).PTFromLP(token_);
            uint256 poolTokenAmount = OraclePrice.amountMax(poolToken, price_);

            return LPool(pool).provideLiquidityOutLPTokens(poolToken, poolTokenAmount);
        }
    }

    modifier onlySupported(address token_) {
        require(isSupported(token_), "OracleLP: Only supported tokens may be used");
        _;
    }
}
