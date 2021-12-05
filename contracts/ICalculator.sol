//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ICalculator {
    /**
     *  @notice gets the amount of approved tokens each pool token is worth
     *  @param _token address
     *  @return _value uint256
     */
    function poolTokenValue(address _token) external view returns (uint256 _value);

    /**
     *  @notice gets the value of a pair of tokens that are either approved or pool tokens
     *  @param _token1 address
     *  @param _token2 address
     *  @return _value uint256
     */
    function pairValue(address _token1, address _token2) external view returns (uint256 _value);

    /**
     *  @notice sets the decimals for the calculator to return
     *  @param _decimals uint256
     */
    function setDecimals(uint256 _decimals) external;

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
}