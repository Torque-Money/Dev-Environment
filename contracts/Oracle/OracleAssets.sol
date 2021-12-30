//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OracleCore.sol";

abstract contract OracleAssets is OracleCore {
    mapping(IERC20 => AggregatorV3Interface) private _priceFeed;
    mapping(IERC20 => AggregatorV3Interface) private _reservePriceFeed;
    mapping(IERC20 => uint256) private _decimals;

    // Set the price feed for a given asset
    function setPriceFeed(IERC20 token_, AggregatorV3Interface priceFeed_, AggregatorV3Interface reservePriceFeed_) external onlyOwner {
        _priceFeed[token_] = priceFeed_;
        _reservePriceFeed[token_] = reservePriceFeed_;
    }

    // Get the price feed for a given asset
    function priceFeed(IERC20 token_) public view returns (AggregatorV3Interface) {
        return _priceFeed[token_];
    }

    // Get the reserve price feed for a given asset
    function reservePriceFeed(IERC20 token_) public view returns (AggregatorV3Interface) {
        return _reservePriceFeed[token_];
    }

    // Get the correct decimals for the given asset
    function setDecimals(IERC20 token_, uint256 decimals_) external onlyOwner {
        _decimals[token_] = decimals_;
    }

    // Get the correct decimals for a given asset
    function decimals(IERC20 token_) public view returns (uint256) {
        return _decimals[token_];
    }
}