//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOracle {
    function priceDecimals() external view returns (uint256);

    function priceMin(IERC20 token_, uint256 amount_) external view returns (uint256);

    function priceMax(IERC20 token_, uint256 amount_) external view returns (uint256);

    function amountMin(IERC20 token_, uint256 price_) external view returns (uint256);

    function amountMax(IERC20 token_, uint256 price_) external view returns (uint256);
}
