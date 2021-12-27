//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Median {
    using SafeMath for uint256;

    function min(uint256[] memory _array, uint256 _start) internal pure returns (uint256) {
        uint256 _min = 2 ** 256 - 1;
        uint256 index = _start;

        for (uint256 i = _start; i < _array.length; i++) {
            if (_array[i] < _min) {
                _min = _array[i];
                index = i;
            }
        }

        return index;
    }

    function swap(uint256[] memory _array, uint256 _i, uint256 _j) internal pure {
        (_array[_i], _array[_j]) = (_array[_j], _array[_i]);
    }

    function sort(uint256[] memory _array) public pure {
        require(_array.length > 0, "Length of array must be greater than 0");

        // Perform selection sort
        for (uint256 i = 0; i < _array.length; i++) {
            uint256 minElem = min(_array, i);
            swap(_array, i, minElem);
        }
    }

    function median(uint256[] memory _array) internal pure returns(uint256) {
        uint256 length = _array.length;
        sort(_array);
        return length.mod(2) == 0 ? _array[length.div(2).sub(1)].add(_array[length.div(2)]).div(2) : _array[length.div(2)];
    }
}