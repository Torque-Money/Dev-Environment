//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OracleAssets.sol";

abstract contract OraclePriceFeed is OracleAssets {
    // Get the price of an asset and the decimals
    function price(IERC20 token_) external view returns (uint256, uint256) {
        AggregatorV3Interface feed = priceFeed(token_);
        (,int result,,,) = feed.latestRoundData();
        uint256 decimals = feed.decimals();

        if (result <= 0) {
            feed = reservePriceFeed(token_);
            (,result,,,) = feed.latestRoundData();
            decimals = feed.decimals();
        }

        return (uint256(result), decimals);
    }
}