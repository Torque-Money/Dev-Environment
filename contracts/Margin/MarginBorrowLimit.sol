//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginCore.sol";

abstract contract MarginBorrowLimit is MarginCore {
    using SafeMath for uint256;

    mapping(IERC20 => uint256) private _limit;

    // Check the limit on an asset
    function limit(IERC20 token_) public view returns (uint256) {
        return _limit[token];
    }

    // Set the maximum amount of the given asset that may be borrowed
    function setLimit(IERC20[] memory token_, uint256[] memory limit_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            _limit[token_[i]] = limit_[i];
            emit SetLimit(token_[i], limit_[i]);
        }
    }

    event SetLimit(IERC20 indexed token, uint256 limit);
}
