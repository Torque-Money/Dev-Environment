//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOracle {
    function priceDecimals() external view returns (uint256);

    function priceMin(address token_, uint256 amount_) external view returns (uint256);

    function priceMax(address token_, uint256 amount_) external view returns (uint256);

    function amountMin(address token_, uint256 price_) external view returns (uint256);

    function amountMax(address token_, uint256 price_) external view returns (uint256);
}
