//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OracleTokens.sol";

abstract contract OraclePriceFeed is OracleTokens {
    using SafeMath for uint256;

    // Get the price of an asset in terms of the stablecoin
    function price(IERC20 token_, uint256 amount_) external view onlySupported(token_) returns (uint256) {
        if (pool.isLPToken(token_)) {
            IERC20 underlying = pool.tokenFromLPToken(token_);
            uint256 redeemValue = pool.redeemValue(token_, amount_);

            token_ = underlying;
            amount_ = redeemValue;
        }

        AggregatorV3Interface feed = priceFeed(token_);
        (,int result,,,) = feed.latestRoundData();
        uint256 _decimals = feed.decimals();

        if (result <= 0) {
            feed = reservePriceFeed(token_);
            (,result,,,) = feed.latestRoundData();
            _decimals = feed.decimals();
        }
        if (result <= 0) result = 0;

        return amount_.mul(uint256(result)).mul(10 ** decimals(token_)).div(_decimals);
    }
}