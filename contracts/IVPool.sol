//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVPool {
    // ======== Tax payouts ========

    function setTaxAccount(address _taxAccount) external;

    // ======== Check the staking period and cooldown periods ========

    /**
     *  @dev Get the period length
     */
    function getPeriodLength() external view returns (uint256);

    /**
     *  @dev Get the cooldown period length
     */
    function getCooldownLength() external view returns (uint256);

    /**
     *  @dev Get the times at which the prologue of the given period occurs
     *  @param _periodId The period to get the times of
     */
    function getPrologueTimes(uint256 _periodId) external view returns (uint256, uint256);

    /**
     *  @dev Checks if the given period is in the prologue phase
     *  @param _periodId The period to check if it is the prologue
     */
    function isPrologue(uint256 _periodId) external view returns (bool);

    /**
     *  @dev Get the times at which the epilogue of the given period occurs
     *  @param _periodId The period to get the times of
     */
    function getEpilogueTimes(uint256 _periodId) external view returns (uint256, uint256);

    /**
     *  @dev Checks if the current period Id is in the epilogue phase
     *  @param _periodId The period to check if it is the epilogue
     */
    function isEpilogue(uint256 _periodId) external view returns (bool);

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
    function approveToken(IERC20 _token) external;

    /**
     *  @dev Returns whether or not a token is approved
     *  @param _token The address of the token to check
     */
    function isApproved(IERC20 _token) external view returns (bool);

    /**
     *  @dev Returns a list of approved tokens
     */
    function getApproved() external view returns (IERC20[] memory);

    // ======== Helper functions ========

    /**
     *  @dev Returns the total locked liquidity for the current period
     *  @param _token The token to check the liquidity of
     *  @param _periodId The period to get the liquidity from
     */
    function getLiquidity(IERC20 _token, uint256 _periodId) external view returns (uint256);

    // ======== Balance management ========

    /**
     *  @dev Returns the deposited balance of a given account for a given token for a given period
     *  @param _account The account to check the deposited balance of
     *  @param _token The token to check the desposited balance of
     *  @param _periodId The id of the period of the balance to be checked
     */
    function balanceOf(address _account, IERC20 _token, uint256 _periodId) external view returns (uint256);

    /**
     *  @dev Returns the value of the tokens for a given period for a given token once they are redeemed
     *  @param _token The token that will be received on redemption
     *  @param _amount The amount of tokens to redeem
     *  @param _periodId The id of the period of which the redeem will occur
     */
    function redeemValue(IERC20 _token, uint256 _amount, uint256 _periodId) external view returns (uint256);

    // ======== Liquidity manipulation ========

    /**
     *  @dev Stakes a given amount of specified tokens in the pool
     *  @param _token The token to stake
     *  @param _amount The amount of the token to stake
     *  @param _periodId The period to stake the tokens into
     */
    function stake(IERC20 _token, uint256 _amount, uint256 _periodId) external;

    /**
     *  @dev Restake an accounts deposited collateral from a different period to the current period
     *  @param _account The account to have its tokens restaked
     *  @param _token The token to restake
     *  @param _periodIdFrom The period to move the deposit from
     */
    function restake(address _account, IERC20 _token, uint256 _periodIdFrom) external;

    /**
     *  @dev Redeems the staked amount of tokens in a given pool
     *  @param _token Token to redeem for
     *  @param _amount Amount of the token to redeem
     *  @param _periodId The id of the period to redeem from
     */
    function redeem(IERC20 _token, uint256 _amount, uint256 _periodId) external;

    /**
     *  @dev Deposit tokens into the pool and increase the liquidity of the pool
     *  @param _token The token to deposit
     *  @param _amount The amount of the token to deposit
     */
    function deposit(IERC20 _token, uint256 _amount) external;

    /**
     *  @dev Withdraw tokens from the pool and decrease the liquidity of the pool
     *  @param _token The token to withdraw
     *  @param _amount The amount of the token to withdraw
     */
    function withdraw(IERC20 _token, uint256 _amount) external;

    // ======== Events ========

    event TaxAccountChange(address indexed newTaxAccount);

    event Stake(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Redeem(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount, uint256 liquidity);

    event Restake(address indexed account, uint256 indexed periodId, IERC20 token, address caller, uint256 periodIdFrom);

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
}