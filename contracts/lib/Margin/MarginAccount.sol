//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract MarginAccount {
    using SafeERC20 for IERC20;

    /** @dev Deposit the given amount of collateral to borrow against a specified asset */
    function deposit(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 periodId = pool.currentPeriodId();

        // Store funds in the account for the given asset they wish to borrow
        _collateral.safeTransferFrom(_msgSender(), address(this), _amount);

        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        borrowAccount.collateral = borrowAccount.collateral.add(_amount);
        emit Deposit(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    /** @dev Withdraw collateral from the account if the account has no debt */
    function withdraw(IERC20 _collateral, IERC20 _borrowed, uint256 _amount, uint256 _periodId) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        BorrowAccount storage borrowAccount = BorrowPeriods[_periodId][_borrowed].collateral[_msgSender()][_collateral];

        require(borrowAccount.borrowed == 0, "Cannot withdraw with outstanding debt, repay first");
        require(borrowAccount.collateral >= _amount, "Insufficient balance to withdraw");

        borrowAccount.collateral = borrowAccount.collateral.sub(_amount);
        _collateral.safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _periodId, _collateral, _borrowed, _amount);
    }

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
}