//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./OracleCore.sol";

abstract contract OracleTokens is OracleCore {
    mapping(IERC20 => bool) private _supported;
    mapping(IERC20 => AggregatorV3Interface) private _priceFeed;
    mapping(IERC20 => AggregatorV3Interface) private _reservePriceFeed;
    mapping(IERC20 => uint256) private _decimals;

    modifier onlySupported(IERC20 token_) {
        require(isAssetSupported(token_), "Only supported tokens may be used");
        _;
    }

    // Check if an asset is supported by the oracle
    function isAssetSupported(IERC20 token_) public view returns (bool) {
        return _supported[token_];
    }

    // Set the price feed for a given asset along with the decimals
    function setPriceFeed(
        IERC20 token_, AggregatorV3Interface priceFeed_, 
        AggregatorV3Interface reservePriceFeed_, uint256 correctDecimals_
    ) external onlyOwner {
        _priceFeed[token_] = priceFeed_;
        _reservePriceFeed[token_] = reservePriceFeed_;
        _decimals[token_] = correctDecimals_;
        _supported[token_] = true;
    }

    // Get the price feed for a given asset
    function priceFeed(IERC20 token_) public view returns (AggregatorV3Interface) {
        return _priceFeed[token_];
    }

    // Get the reserve price feed for a given asset
    function reservePriceFeed(IERC20 token_) public view returns (AggregatorV3Interface) {
        return _reservePriceFeed[token_];
    }

    // Get the correct decimals for a given asset
    function decimals(IERC20 token_) public view returns (uint256) {
        return _decimals[token_];
    }
}