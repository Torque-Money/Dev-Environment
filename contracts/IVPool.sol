//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IVPool {
    // ======== Check the staking period and cooldown periods ========

    /**
     *  @dev Checks if the period Id is on a cooldown
     *  @param _periodId The id of the period to check if it is on cooldown
     */
    function isCooldown(uint256 _periodId) external view returns (bool);

    /**
     *  @dev Checks if the current period is on cooldown
     */
    function isCooldown() external view returns (bool);

    /**
     *  @dev Checks if the specified period is the current period
     *  @param _periodId The id of the period to check
     */
    function isCurrentPeriod(uint256 _periodId) external view returns (bool);

    /**
     *  @dev Returns the id of the current period
     */
    function currentPeriodId() external view returns (uint256);

    // ======== Approved tokens ========

    /**
     *  @dev Approves a token for use with the protocol
     *  @param _token The address of the token to approve
     */
    function approveToken(address _token) external;

    /**
     *  @dev Returns whether or not a token is approved
     *  @param _token The address of the token to check
     */
    function isApproved(address _token) external view returns (bool);

    /**
     *  @dev Returns a list of approved tokens
     */
    function getApproved() external view returns (address[] memory);

    // ======== Balance management ========

    /**
     *  @dev Returns the deposited balance of a given account for a given token for a given period
     *  @param _account The account to check the deposited balance of
     *  @param _token The token to check the desposited balance of
     *  @param _periodId The id of the period of the balance to be checked
     */
    function balanceOf(address _account, address _token, uint256 _periodId) external view returns (uint256);

    /**
     *  @dev Returns the deposited balance of a given account for a given token at the current period
     *  @param _account The account to check the deposited balance of
     *  @param _token The token to check the deposited balance of
     */
    function balanceOf(address _account, address _token) external view returns (uint256);

    /**
     *  @dev Returns the value of the tokens for a given period for a given token once they are redeemed
     *  @param _token The token that will be received on redemption
     *  @param _periodId The id of the period of which the redeem will occur
     *  @param _amount The amount of tokens to redeem
     */
    function redeemValue(address _token, uint256 _periodId, uint256 _amount) external view returns (uint256);

    // ======== Liquidity manipulation ========

    /**
     *  @dev Stakes a given amount of specified tokens in the pool
     *  @param 
     */
    function stake(address _token, uint256 _amount) external;

    function redeem(address _token, uint256 _amount, uint256 _periodId) external;

    function deposit(address _token, uint256 _amount) external;

    function withdraw(address _token, uint256 _amount, address _to) external;

    // ======== Events ========

    event Stake(address indexed sender, address indexed token, uint256 indexed periodId, uint256 amount);
    event Redeem(address indexed sender, address indexed token, uint256 indexed periodId, uint256 amount, uint256 liquidity);

    event Deposit(address indexed token, uint256 indexed periodId, uint256 amount);
    event Withdraw(address indexed token, uint256 indexed periodId, address indexed to, uint256 amount);
}