//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface Calculator {
    /**
     *  @notice gets the amount of approved tokens each pool token is worth
     *  @param _token address
     *  @return _value uint256
     */
    function poolTokenValue(address _token) external view returns (uint256 _value);

    /**
     *  @notice gets the value of an approved token pair - tokens can be pool tokens
     */
    function pairValue(address _token1, address _token2) external view returns (uint256 _value);

    function setDecimals(uint256 _decimals) external;

    function setRouterAddress(address _router) external;

    function setLPoolAddress(address _lPool) external;
}