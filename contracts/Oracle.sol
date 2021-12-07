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

    function _swap(int256[] memory array, uint256 i, uint256 j) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function _sort(int256[] memory array, uint256 begin, uint256 end) private pure {
        if (begin < end) {
            uint256 j = begin;
            int256 pivot = array[j];
            for (uint256 i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    _swap(array, i, ++j);
                }
            }
            _swap(array, begin, j);
            _sort(array, begin, j);
            _sort(array, j + 1, end);
        }
    }

    function _median(uint256[] memory array) private pure returns(int256) {
        uint256 length = array.length;
        _sort(array, 0, length);
        return length % 2 == 0 ? array[length/2-1].add(array[length/2]).div(2) : array[length/2];
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