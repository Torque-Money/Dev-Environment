//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOracle {
    // Get the price for a given token amount at the lowest threshold by the oracle
    function priceMin(IERC20 token_, uint256 amount_) external view returns (uint256);

    // Get the price for a given token amount at the highest threshold by the oracle
    function priceMax(IERC20 token_, uint256 amount_) external view returns (uint256);

    // Get the amount for a given token price at the lowest threshold by the oracle
    function amountMin(IERC20 token_, uint256 price_) external view returns (uint256);

    // Get the amount for a given token price at the highest threshold by the oracle
    function amountMax(IERC20 token_, uint256 price_) external view returns (uint256);
}
