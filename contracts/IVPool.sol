//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IVPool {
    // ======== Check the staking period and cooldown periods ========

    function isCooldown(uint256 _periodId) external view returns (bool);

    function isCooldown() external view returns (bool);

    function isCurrentPeriod(uint256 _periodId) external view returns (bool);

    function currentPeriodId() external view returns (uint256);

    // ======== Approved tokens ========

    function approveToken(address _token) external;

    function isApproved(address _token) external view returns (bool);

    function getApproved() external view returns (address[] memory);

    // ======== Balance management ========

    function balanceOf(address _account, address _token, uint256 _periodId) external view returns (uint256);

    function balanceOf(address _account, address _token) external view returns (uint256);

    function redeemValue(address _token, uint256 _periodId, uint256 _amount) external view returns (uint256);

    // ======== Liquidity manipulation ========

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