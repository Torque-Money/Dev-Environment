//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOracle {
    function pairPrice(address _token1, address _token2) external view returns (uint256);

    function getDecimals() external view returns (uint256);
}