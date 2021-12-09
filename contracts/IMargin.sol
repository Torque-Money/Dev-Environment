//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMargin {
    // ======== Calculations ========

    function compensationPercentage() external view returns (uint256);

    function liquidityAvailable(IERC20 _token) external view returns (uint256);

    function calculateMarginLevel(uint256 _deposited, uint256 _initialBorrowPrice, uint256 _amountBorrowed, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256);

    function getMinMarginLevel() external view returns (uint256);

    function getMarginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256);

    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow) external view returns (uint256);

    // ======== Deposit ========

    function deposit(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external;

    // ======== Borrow ========

    function borrow(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external;

    // ======== Repay and withdraw ========

    function balanceOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external view returns (uint256);

    function repay(address _account, IERC20 _collateral, IERC20 _borrowed) external;

    function repay(IERC20 _collateral, IERC20 _borrowed) external;

    function withdraw(IERC20 _collateral, IERC20 _borrowed, uint256 _periodId, uint256 _amount) external;

    // ======== Liquidate ========

    function isLiquidatable(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (bool);

    function flashLiquidate(address _account, IERC20 _collateral, IERC20 _borrowed) external;

    // ======== Events ========

    // **** I went and changed these, CHANGE them back please

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);

    event Borrow(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event Repay(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 balance);

    event FlashLiquidation(address indexed account, uint256 indexed periodId, address indexed liquidator, IERC20 collateral, IERC20 borrowed, uint256 amount);
}