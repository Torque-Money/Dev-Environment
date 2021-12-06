//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// **** New proposal: Oracle which tracks the price of the DEX repeatedly and records the data so that flashloaners CANNOT manipulate a pool and then liquidate our users in the same transaction
// **** Users are rewarded in the amount of time between the previous data fetch and the current one in the form of treasury tokens for the DAO
// **** Users may only call more price data after a given amount of time to avoid the same flash loan attacks by manipulating all of the prices in the same transaction
// **** At least SOME form of time decay is going to be necessary to prevent flash loans in the same transaction destroying the pool where they cant change the price in the same transaction
// **** Perhaps you must request the price, and then you can execute the trade for that requested price in a different transaction ?

interface IOracle {
    /**
     *  @notice requests the value of a price for a user - the purpose is to seperate the calls for the request for the price and the time of consuming the price to prevent flash loan manipulation
     *  @param _token1 address
     *  @param _token2 address
     */
    function requestValue(address _token1, address _token2) external;

    /**
     *  @notice consumes the price requested as long as it falls within a given time frame and as long as a price has been requested
     *  @param _token1 address
     *  @param _token2 address
     */
    function useRequestedValue(address _token1, address _token2) external view returns (uint256);

    /**
     *  @notice gets the number of token2 returned for token1
     *  @param _token1 address
     *  @param _token2 address
     *  @return _value uint256
     */
    function pairValue(address _token1, address _token2) external view returns (uint256 _value);

    /**
     *  @notice sets the Uniswap router address
     *  @param _router address
     */
    function setRouterAddress(address _router) external;

    /**
     *  @notice sets the liquidity pool address
     *  @param _lPool address
     */
    function setLPoolAddress(address _lPool) external;

    /**
     *  @notice gets the decimals that the calculator returns
     *  @return _decimals uint256
     */
    function getDecimals() external view returns (uint256 _decimals);

    /**
     *  @notice gets the request expiry timeframe
     *  @return _requestExpiry uint256
     */
    function getRequestExpiry() external view returns (uint256 _requestExpiry);

    /**
     *  @notice gets the interest interval
     *  @return _interestInterval uint256
     */
    function getInterestInterval() external view returns (uint256 _interestInterval);

    /**
     *  @notice returns the amount of outstanding tokens lended by the pool
     *  @param _token address
     *  @return _value uint256
     */
    function getPoolLended(address _token) external view returns (uint256 _value);

    /**
     *  @notice returns the interest accumulated as a percent of a given borrowed asset from a given timestamp
     *  @param _token address
     *  @param _since uint256
     *  @return _interest uint256
     */
    function calculateInterest(address _token, uint256 _since) external view returns (uint256 _interest);
}