//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../LPool/LPool.sol";

contract OracleCore is Ownable {
    AggregatorV3Interface public priceFeed;
    LPool public pool;

    constructor(AggregatorV3Interface priceFeed_, LPool pool_) {
        priceFeed = priceFeed_;
        pool = pool_;
    }

    // Set the price feed
    function setPriceFeed(AggregatorV3Interface priceFeed_) external onlyOwner {
        priceFeed = priceFeed_;
    }

    // Set the pool
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }
}