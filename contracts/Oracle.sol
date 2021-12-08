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

    mapping(UniswapV2Router02 => bool) private storedRouters;

    constructor(uint256 decimals_) {
        decimals = decimals_;
    }

    function getDecimals() public view override returns (uint256) {
        return decimals;
    }

    function addRouter(UniswapV2Router02 _router) external {
        require(storedRouters[_router] != true, "This router has already been added");
        routers.push(_router);
        storedRouters[_router] = true;
    }

    // ======== Verify price from multiple sources ========

    function _min(uint256[] memory _array, uint256 _start) private pure returns (uint256) {
        uint256 min = 2 ** 256 - 1;
        uint256 index = _start;

        for (uint256 i = _start; i < _array.length; i++) {
            if (_array[i] < min) {
                min = _array[i];
                index = i;
            }
        }

        return index;
    }

    function _swap(uint256[] memory _array, uint256 _i, uint256 _j) private pure {
        (_array[_i], _array[_j]) = (_array[_j], _array[_i]);
    }

    function _sorted(uint256[] memory _array) private pure returns(uint256[] memory) {
        require(_array.length > 0, "Length of array must be greater than 0");

        // Perform selection sort
        uint256[] memory sorted = new uint256[](_array.length);
        for (uint256 i = 0; i < _array.length; i++) {
            uint256 minElem = _min(_array, i);
            _swap(_array, i, minElem);
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
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        // Get the median price of token2 earned from token1 from the different exchanges
        uint256[] memory prices = new uint256[](routers.length);
        for (uint256 i = 0; i < routers.length; i++) {
            prices[i] = routers[i].getAmountsOut(decimals, path)[1];
        }
        return _median(prices);
    }

    function getRouter() external view returns (UniswapV2Router02) {
        uint256 index = uint256(keccak256(abi.encodePacked(_msgSender()))).mod(routers.length);
        return routers[index];
    }
}