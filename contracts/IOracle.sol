//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOracle {
    function requestValue(address _token1, address _token2) external;

    function useRequestedValue(address _token1, address _token2) external view returns (uint256);

    function pairValue(address _token1, address _token2) external view returns (uint256 _value);

    function setRouterAddress(address _router) external;

    function setLPoolAddress(address _lPool) external;

    function getDecimals() external view returns (uint256 _decimals);

    function getRequestExpiry() external view returns (uint256 _requestExpiry);

    function getInterestInterval() external view returns (uint256 _interestInterval);

    function getPoolLended(address _token) external view returns (uint256 _value);

    function calculateInterest(address _token, uint256 _timeframe, uint256 _amount) external view returns (uint256 _interest);
}