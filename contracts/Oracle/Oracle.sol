//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OracleTokens.sol";

abstract contract Oracle is OracleTokens {
    using SafeMath for uint256;

    // Get the price of an asset in terms of the default stablecoin
    function price(IERC20 token_, uint256 amount_) public view onlySupported(token_) returns (uint256) {
        AggregatorV3Interface feed = priceFeed(token_);
        (, int256 result, , , ) = feed.latestRoundData();
        uint256 _decimals = feed.decimals();

        if (result <= 0) {
            feed = reservePriceFeed(token_);
            (, result, , , ) = feed.latestRoundData();
            _decimals = feed.decimals();
        }
        if (result <= 0) return 0;

        return uint256(result).mul(10**decimals(defaultStablecoin)).div(10**_decimals).mul(amount_).div(10**decimals(token_));
    }

    // Get the amount of an asset from the price
    function amount(IERC20 token_, uint256 price_) external view returns (uint256) {
        uint256 tokenPrice = price(token_, 10**decimals(token_));
        return price_.mul(10**decimals(token_)).div(tokenPrice);
    }
}
