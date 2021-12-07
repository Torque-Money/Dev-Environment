//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IOracle.sol";
import "./lib/UniswapV2Router02.sol";

contract Oracle is IOracle, Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    UniswapV2Router02 private router;

    uint256 private decimals;

    struct RequestedPrice {
        uint256 price;
        uint256 timeRequested;
    }
    mapping(bytes => RequestedPrice) private requestedPrices;
    uint256 requestExpiry;

    constructor(UniswapV2Router02 router_, uint256 decimals_, uint256 requestExpiry_) {
        router = router_;
        decimals = decimals_;
        requestExpiry = requestExpiry_;
    }

    function requestPrice(address _token1, address _token2) public override {
        // Get the pair hash and timestamp of the request
        bytes memory pairId = abi.encodePacked(_token1, _token2);
        uint256 timestamp = block.timestamp;
        uint256 price = pairPrice(_token1, _token2);

        // Record the timestamp and the value of the request
        requestedPrices[pairId] = RequestedPrice({
            price: price,
            timeRequested: timestamp
        });
    }

    function useRequestedPrice(address _token1, address _token2) public view override returns (uint256) {
        // Get the requested value
        bytes memory pairId = abi.encodePacked(_token1, _token2);
        RequestedPrice memory req = requestedPrices[pairId];

        // Check that the consumer requested the value between a specific amount of time
        require(block.timestamp > req.timeRequested, "You must wait for the cooldown period to expire before consuming this value");
        require(block.timestamp < req.timeRequested + requestExpiry, "This requested price has expired, please request again");

        // Return the requested value for use
        return req.price;
    }

    function getRequestExpiry() public view override returns (uint256) {
        return requestExpiry;
    }

    function pairPrice(address _token1, address _token2) public view override returns (uint256) {
        // If they are the same return 1 to 1 conversion
        if (_token1 == _token2) return decimals;

        // Update the path if the tokens are pool tokens, and return the converted values if we are trying to compare the pool asset with its approved asset
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;

        // Get the amount of token2 earned from token1
        uint256 price = router.getAmountsOut(decimals, path)[1];
        return price;
    }

    function getDecimals() public view override returns (uint256) {
        return decimals;
    }
}