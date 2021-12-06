//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// **** New proposal: Oracle which tracks the price of the DEX repeatedly and records the data so that flashloaners CANNOT manipulate a pool and then liquidate our users in the same transaction
// **** Users are rewarded in the amount of time between the previous data fetch and the current one in the form of treasury tokens for the DAO
// **** Users may only call more price data after a given amount of time to avoid the same flash loan attacks by manipulating all of the prices in the same transaction
// **** At least SOME form of time decay is going to be necessary to prevent flash loans in the same transaction destroying the pool where they cant change the price in the same transaction
// **** Perhaps you must request the price, and then you can execute the trade for that requested price in a different transaction ?

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