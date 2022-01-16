//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract OracleTokens is Ownable {
    struct Token {
        AggregatorV3Interface priceFeed;
        AggregatorV3Interface reservePriceFeed;
        uint256 decimals;
        bool supported;
    }

    mapping(IERC20 => Token) private _tokens;
    uint256 public priceDecimals;

    constructor(uint256 priceDecimals_) {
        priceDecimals = priceDecimals_;
    }

    modifier onlySupported(IERC20 token_) {
        require(isSupported(token_), "OracleTokens: Only supported tokens may be used");
        _;
    }

    // Set the price feed for a given asset along with the decimals
    function setPriceFeed(
        IERC20[] memory token_,
        AggregatorV3Interface[] memory priceFeed_,
        AggregatorV3Interface[] memory reservePriceFeed_,
        uint256[] memory correctDecimals_,
        bool[] memory supported_
    ) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            Token storage token = _tokens[token_[i]];

            token.priceFeed = priceFeed_[i];
            token.reservePriceFeed = reservePriceFeed_[i];
            token.decimals = correctDecimals_[i];
            token.supported = supported_[i];
        }
    }

    // Check if an asset is supported by the oracle
    function isSupported(IERC20 token_) public view returns (bool) {
        return _tokens[token_].supported;
    }

    // Set the price decimals
    function setPriceDecimals(uint256 priceDecimals_) external onlyOwner {
        priceDecimals = priceDecimals_;
    }

    // Get the price feed for a given asset
    function priceFeed(IERC20 token_) public view returns (AggregatorV3Interface) {
        return _tokens[token_].priceFeed;
    }

    // Get the reserve price feed for a given asset
    function reservePriceFeed(IERC20 token_) public view returns (AggregatorV3Interface) {
        return _tokens[token_].reservePriceFeed;
    }

    // Get the correct decimals for a given asset
    function decimals(IERC20 token_) public view returns (uint256) {
        return _tokens[token_].decimals;
    }
}
