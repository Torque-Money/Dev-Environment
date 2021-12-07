//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOracle {
    function requestPrice(address _token1, address _token2) external;

    function useRequestedPrice(address _token1, address _token2) external view returns (uint256);

    function getRequestExpiry() external view returns (uint256);

    function pairPrice(address _token1, address _token2) external view returns (uint256);

    function getDecimals() external view returns (uint256);
}