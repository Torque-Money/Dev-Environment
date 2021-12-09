//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMargin {
    // ======== Calculations ========

    function liquidityAvailable(IERC20 _token) external view returns (uint256);

    function calculateMarginLevel(uint256 _deposited, uint256 _initialBorrowPrice, uint256 _amountBorrowed, IERC20 _borrowed, IERC20 _collateral) external view returns (uint256);

    function getMinMarginLevel() external view returns (uint256);

    function getMarginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256);

    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow) external view returns (uint256);

    // ======== Deposit ========

    function deposit(IERC20 _collateral, uint256 _amount, IERC20 _borrow) external;

    // ======== Borrow ========

    function borrow(IERC20 _borrow, IERC20 _collateral, uint256 _amount) external;

    // ======== Repay and withdraw ========

    function balance(address _account, IERC20 _collateral, IERC20 _borrow, uint256 _periodId) external view returns (uint256);

    function repay(address _account, IERC20 _collateral, IERC20 _borrow) external;

    function repay(IERC20 _collateral, IERC20 _borrow) external;

    function withdraw(IERC20 _collateral, IERC20 _borrow, uint256 _periodId, uint256 _amount) external;

    // ======== Liquidate ========

    function isLiquidatable(address _account, IERC20 _borrow, IERC20 _collateral) external view returns (bool);

    function flashLiquidate(address _account, IERC20 _borrow, IERC20 _collateral) external;

    // ======== Events ========

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral, uint256 amount);

    event Borrow(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral, uint256 amount);
    event Repay(address indexed account, uint256 indexed periodId, IERC20 borrowed, IERC20 collateral, uint256 balance);

    event FlashLiquidation(address indexed account, uint256 indexed periodId, address indexed liquidator, IERC20 borrowed, IERC20 collateral, uint256 amount);
}