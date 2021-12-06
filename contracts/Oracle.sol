//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ILPool.sol";
import "./IOracle.sol";
import "./lib/UniswapV2Router02.sol";

// **** Now I need to implement some sort of way of calculating the interest rates from this ???

contract Oracle is IOracle, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private decimals;

    address private router;
    address private lPool;

    struct RequestedValue {
        uint256 value;
        uint256 timeRequested;
    }
    mapping(address => mapping(bytes => RequestedValue)) private requestedValues;
    uint256 requestedExpiry;

    constructor(address router_, address lPool_, uint256 decimals_, uint256 requestedExpiry_) {
        router = router_;
        lPool = lPool_;
        decimals = decimals_;
        requestedExpiry = requestedExpiry_;
    }

    function requestValue(address _token1, address _token2) public override {
        // Get the pair hash and timestamp of the request
        bytes memory pairId = abi.encodePacked(_token1, _token2);
        uint256 timestamp = block.timestamp;
        uint256 value = pairValue(_token1, _token2);

        // Record the timestamp and the value of the request
        requestedValues[_msgSender()][pairId] = RequestedValue({
            value: value,
            timeRequested: timestamp
        });
    }

    function useRequestedValue(address _token1, address _token2) public view override returns (uint256) {
        // Get the requested value
        bytes memory pairId = abi.encodePacked(_token1, _token2);
        RequestedValue memory req = requestedValues[_msgSender()][pairId];

        // Check that the consumer requested the value between a specific amount of time
        require(block.timestamp > req.timeRequested, "You must wait for the cooldown period to expire before consuming this value");
        require(block.timestamp < req.timeRequested + requestedExpiry, "This requested price has expired, please request again");

        // Return the requested value for use
        return req.value;
    }

    /**
     *  @notice gets the amount of approved tokens each pool token is worth
     *  @param _token address
     *  @return _value uint256
     */
    function _poolTokenValue(address _token) internal view returns (uint256 _value) {
        // Validate that the token is valid
        ILPool pool = ILPool(lPool);
        require(pool.isPoolToken(_token), "Invalid pool token");
        address approvedAsset = pool.getApprovedAsset(_token);

        // Find how much approved asset each pool token is worth
        uint256 numerator = decimals.mul(IERC20(approvedAsset).balanceOf(lPool));
        uint256 denominator = IERC20(_token).totalSupply();
        _value = numerator.div(denominator.add(1)); // Prevent division by 0 errors
    }

    function pairValue(address _token1, address _token2) public view override returns (uint256 _value) {
        // Make sure that the tokens are valid
        ILPool pool = ILPool(lPool);
        require(pool.isApprovedAsset(_token1) || pool.isPoolToken(_token1), "Token 1 is not an approved asset or pool token");
        require(pool.isApprovedAsset(_token2) || pool.isPoolToken(_token2), "Token 2 is not an approved asset or pool token");

        // Trivial case
        if (_token1 == _token2) {
            return decimals;
        }

        // Update the path if the tokens are pool tokens, and return the converted values if we are trying to compare the pool asset with its approved asset
        address[] memory path = new address[](2);
        if (pool.isPoolToken(_token1)) {
            address approvedAsset = pool.getApprovedAsset(_token1);
            path[0] = approvedAsset;

            // Case that we are swapping from pool to approved
            if (_token2 == approvedAsset) {
                return _poolTokenValue(_token1);
            } 
        } else {
            path[0] = _token1;

            // Case that we are swapping from approved to pool
            if (_token2 == pool.getPoolToken(_token1)) {
                return decimals.mul(decimals).div(_poolTokenValue(_token2).add(1));
            }
        }

        if (pool.isPoolToken(_token2)) {
            path[1] = pool.getApprovedAsset(_token2);
        } else {
            path[1] = _token2;
        }

        // Get the amount of token2 earned from token1
        uint256 asset1ToAsset2 = UniswapV2Router02(router).getAmountsOut(decimals, path)[1];

        // Now consider the value of the pool tokens along with the swapped value
        if (pool.isPoolToken(_token1) && pool.isPoolToken(_token2)) {
            uint256 token1ToAsset = _poolTokenValue(_token1);
            uint256 token2ToAsset = _poolTokenValue(_token2);

            _value = token1ToAsset.mul(asset1ToAsset2).div(token2ToAsset.add(1)); // Add one to avoid division by 0

        } else if (pool.isPoolToken(_token1)) {
            uint256 token1ToAsset = _poolTokenValue(_token1);
            _value = asset1ToAsset2.mul(token1ToAsset).div(decimals.add(1)); // Add one to avoid division by 0

        } else if (pool.isPoolToken(_token2)) {
            uint256 token2ToAsset = _poolTokenValue(_token2);
            _value = asset1ToAsset2.mul(decimals).div(token2ToAsset.add(1)); // Add one to avoid division by 0

        } else {
            _value = asset1ToAsset2;
        }
    }

    function getPoolLiquidity(address _token) public view override returns (uint256 _value) {
        // Get the full list of backed assets
        address[] memory assets = ILPool(lPool).getApprovedAssets();

        // Sum the values of each asset times the amount in each pool
        _value = 0;
        for (uint i = 0; i < assets.length; i++) {
            uint256 value = pairValue(assets[i], _token);
            uint256 amount = IERC20(assets[i]).balanceOf(lPool);
            _value = _value.add(value.mul(amount).div(decimals.add(1))); // Add 1 to avoid division by zero error
        }
    }

    function getPoolLended(address _token) public view override returns (uint256 _value) {
        return 0; // **** NEEDS IMPLEMENTATION
    }

    function getPoolTotal(address _token) public view override returns (uint256 _value) {
        return getPoolLiquidity(_token).add(getPoolLended(_token));
    }

    function calculateInterest(address _token) public view override returns (uint256 _interest) {

    }

    function setRouterAddress(address _router) public override onlyOwner {
        router = _router;
    }

    function setLPoolAddress(address _lPool) public override onlyOwner {
        lPool = _lPool;
    }

    function getDecimals() public view override returns (uint256 _decimals) {
        _decimals = decimals;
    }
}