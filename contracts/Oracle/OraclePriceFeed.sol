//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OracleAssets.sol";

abstract contract OraclePriceFeed is OracleAssets {
    using SafeMath for uint256;

    // Get the price of an asset and the decimals
    function price(IERC20 token_, uint256 amount_) external view returns (uint256, uint256) {
        AggregatorV3Interface feed = priceFeed(token_);
        (,int result,,,) = feed.latestRoundData();
        uint256 decimals = feed.decimals();

        if (result <= 0) {
            feed = reservePriceFeed(token_);
            (,result,,,) = feed.latestRoundData();
            decimals = feed.decimals();
        }

        return (uint256(result), decimals); // **** What exactly is returned back to us ? The price in TERMS of the decimals or????
        // **** As long as the data is consistent when talking about returns it should be safe I believe ?

        // **** I NEED TO ADD THE LP TOKENS INTO THIS (what do we even do for this...?)
    }
}