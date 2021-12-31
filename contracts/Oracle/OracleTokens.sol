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

    IERC20 public defaultStablecoin;

    modifier onlySupported(IERC20 token_) {
        require(isSupported(token_), "Only supported tokens may be used");
        _;
    }

    // Check if an asset is supported by the oracle
    function isSupported(IERC20 token_) public view returns (bool) {
        return _supported[token_] || _supported[pool.PAFromLP(token_)];
    }

    // Set the price feed for a given asset along with the decimals
    function setPriceFeed(
        IERC20[] memory token_, AggregatorV3Interface[] memory priceFeed_, 
        AggregatorV3Interface[] memory reservePriceFeed_, uint256[] memory correctDecimals_, bool[] memory supported_
    ) external onlyOwner {
        for (uint i = 0; i < token_.length; i++) {
            _priceFeed[token_[i]] = priceFeed_[i];
            _reservePriceFeed[token_[i]] = reservePriceFeed_[i];
            _decimals[token_[i]] = correctDecimals_[i];
            _supported[token_[i]] = supported_[i];
        }
    }

    // Set the default stablecoin to convert the prices into
    function setDefaultStablecoin(IERC20 token_) external onlyOwner onlySupported(token_) {
        defaultStablecoin = token_;
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