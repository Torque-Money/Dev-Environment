//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOracle {
    function pairPrice(IERC20 _token1, IERC20 _token2) external view returns (uint256);

    function getDecimals() external view returns (uint256);
}