//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

contract OracleTest is IOracle {
    mapping(IERC20 => uint256) private _prices;

    function setPrice(IERC20 token_, uint256 price_) external {
        _prices[token_] = price_;
    }

    function _price(IERC20 token_) internal view returns (uint256) {
        return _prices[token_];
    }

    function priceMin(IERC20 token_, uint256 amount_) external view returns (uint256) {}

    function priceMax(IERC20 token_, uint256 amount_) external view returns (uint256) {}

    function amountMin(IERC20 token_, uint256 price_) external view returns (uint256) {}

    function amountMax(IERC20 token_, uint256 price_) external view returns (uint256) {}
}
