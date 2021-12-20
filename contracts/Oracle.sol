//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/UniswapV2Router02.sol";

contract Oracle is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    UniswapV2Router02[] private Routers;
    mapping(UniswapV2Router02 => bool) private StoredRouters;

    uint256 public immutable decimals;

    constructor(uint256 decimals_) {
        decimals = decimals_;
    }

    // ======== Routers ========

    /** @dev Adds a new router to be used in price calculation */
    function addRouter(UniswapV2Router02 _router) external onlyOwner {
        require(StoredRouters[_router] != true, "This router has already been added");
        Routers.push(_router);
        StoredRouters[_router] = true;
    }

    /** @dev Return the list of routers used in the oracle */
    function routers() external view returns (UniswapV2Router02[] memory) { return Routers; }

    /** @dev Returns a pseudo-random router to use */
    function router() external view returns (UniswapV2Router02) {
        uint256 index = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp))).mod(Routers.length);
        return Routers[index];
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

    function _sort(uint256[] memory _array) private pure {
        require(_array.length > 0, "Length of array must be greater than 0");

        // Perform selection sort
        for (uint256 i = 0; i < _array.length; i++) {
            uint256 minElem = _min(_array, i);
            _swap(_array, i, minElem);
        }
    }

    function _median(uint256[] memory _array) private pure returns(uint256) {
        uint256 length = _array.length;
        _sort(_array);
        return length.mod(2) == 0 ? _array[length.div(2).sub(1)].add(_array[length.div(2)]).div(2) : _array[length.div(2)];
    }

    /** @dev Returns the median price of the tokens passed to it over the stored exchanges */
    function pairPrice(IERC20 _token1, IERC20 _token2) public view returns (uint256) {
        // Update the path if the tokens are pool tokens, and return the converted values if we are trying to compare the pool asset with its approved asset
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        // Get the median price of token2 earned from token1 from the different exchanges
        uint256[] memory prices = new uint256[](Routers.length);
        for (uint256 i = 0; i < Routers.length; i++) {
            prices[i] = Routers[i].getAmountsOut(decimals, path)[1];
        }
        return _median(prices);
    }
}