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

    UniswapV2Router02[] private routers;
    uint256 private decimals;

    constructor(uint256 decimals_) {
        decimals = decimals_;
    }

    // ======== Verify price from multiple sources ========

    function _min(uint256[] memory _array, uint256 _start) private pure {
        uint256 min = uint256(-1);
        uint256 index = _start;

        for (uint256 i = _start; i < _array.length; i++) {
            if (_array[i] < min) {
                min = _array[i];
                index = i;
            }
        }

        return index;
    }

    function _sorted(uint256[] memory _array) private pure returns(uint256[] memory) {
        uint256[] memory sorted = new uint256[](_array.length);
        for (uint256 i = 0; i < _array.length; i++) {
            sorted[i] = _min(_array, i);
        }
        return sorted;
    }

    function _median(uint256[] memory _array) private pure returns(uint256) {
        uint256 length = _array.length;
        _sorted(_array);
        return length % 2 == 0 ? _array[length/2-1].add(_array[length/2]).div(2) : _array[length/2];
    }

    function pairPrice(IERC20 _token1, IERC20 _token2) public view override returns (uint256) {
        // If they are the same return 1 to 1 conversion
        if (_token1 == _token2) return decimals;

        // Update the path if the tokens are pool tokens, and return the converted values if we are trying to compare the pool asset with its approved asset
        IERC20[] memory path = new IERC20[](2);
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