//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract MarginBorrow {
    uint256 public minBorrowLength;
    mapping(IERC20 => uint256) private MinCollateral;

    /** @dev Set the minimum borrow length */
    function setMinBorrowLength(uint256 _minBorrowLength) external onlyOwner {
        minBorrowLength = _minBorrowLength;
    }

    /** @dev Get the most recent borrow time for a given account */
    function minBorrowTimeRemaining(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.borrowTime;
    }

    /** @dev Gets the minimum amount of collateral required to borrow a token */
    function minCollateral(IERC20 _token) public view returns (uint256) {
        return MinCollateral[_token];
    }

    /** @dev Set the minimum amount of collateral for a given token required to borrow against */
    function setMinCollateral(IERC20 _token, uint256 _amount) external onlyApproved(_token) onlyOwner {
        MinCollateral[_token] = _amount;
    }

    /** @dev Return the total amount of a given asset borrowed */
    function borrowed(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        return BorrowPeriods[periodId][_token].totalBorrowed;
    }

    /** @dev Borrow a specified number of the given asset against the collateral */
    function borrow(IERC20 _collateral, IERC20 _borrowed, uint256 _amount) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        uint256 periodId = pool.currentPeriodId();
        require(_amount > 0, "Amount must be greater than 0");
        require(!pool.isPrologue(periodId) && !pool.isEpilogue(periodId), "Cannot borrow during the prologue or epilogue");
        require(pool.liquidity(_borrowed, periodId) >= _amount, "Amount to borrow exceeds available liquidity");
        require(_collateral != _borrowed, "Cannot borrow against the same asset");

        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_msgSender()][_collateral];

        require(borrowAccount.collateral > 0 && borrowAccount.collateral >= minCollateral(_collateral), "Not enough collateral to borrow against");

        _borrow(borrowAccount, borrowPeriod, _collateral, _borrowed, _amount);

        emit Borrow(_msgSender(), periodId, _collateral, _borrowed, _amount);
    }

    /** @dev Require that the borrow is not instantly liquidatable and update the balances */
    function _borrow(BorrowAccount storage _borrowAccount, BorrowPeriod storage _borrowPeriod, IERC20 _collateral, IERC20 _borrowed, uint256 _amount) internal {
        if (_borrowAccount.borrowed == 0) _borrowAccount.initialBorrowTime = block.timestamp;

        // Require that the borrowed amount will be above the required margin level
        uint256 borrowInitialPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amount).div(oracle.decimals());
        uint256 interest = calculateInterest(_borrowed, _borrowAccount.initialPrice.add(borrowInitialPrice), _borrowAccount.initialBorrowTime);
        require(
            _marginLevel(
                _borrowAccount.collateral, _borrowAccount.initialPrice.add(borrowInitialPrice),
                _borrowAccount.borrowed.add(_amount), _collateral, _borrowed, interest
            ) > _minMarginLevel(), "This deposited collateral is not enough to exceed minimum margin level"
        );

        _borrowPeriod.totalBorrowed = _borrowPeriod.totalBorrowed.add(_amount);
        _borrowPeriod.borrowed[_msgSender()] = _borrowPeriod.borrowed[_msgSender()].add(_amount);
        _borrowAccount.initialPrice = _borrowAccount.initialPrice.add(borrowInitialPrice);
        _borrowAccount.borrowed = _borrowAccount.borrowed.add(_amount);
        _borrowAccount.borrowTime = block.timestamp;

        pool.claim(_borrowed, _amount);
    }

    /** @dev Repay the borrowed amount for the given asset and collateral */
    function repay(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        // If the period has entered the epilogue phase, then anyone may repay the account
        require(_account == _msgSender() || pool.isEpilogue(_periodId) || !pool.isCurrentPeriod(_periodId), "Only the owner may repay before the epilogue period");

        // Repay off the margin and update the users collateral to reflect it
        BorrowPeriod storage borrowPeriod = BorrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        require(borrowAccount.borrowed > 0, "No debt to repay");
        require(block.timestamp > borrowAccount.borrowTime + minBorrowLength || pool.isEpilogue(_periodId),
                "Cannot repay until minimum borrow period is over or epilogue has started");

        pool.unclaim(_borrowed, _borrowAccount.collateral);
        uint256 balAfterRepay = balanceOf(_account, _collateral, _borrowed, _periodId);
        if (balAfterRepay > borrowAccount.collateral) _repayGreater(_account, _collateral, _borrowed, balAfterRepay, borrowPeriod, borrowAccount);
        else _repayLessEqual(_account, _collateral, _borrowed, balAfterRepay, borrowPeriod, borrowAccount);

        // Update the borrowed
        _borrowAccount.initialPrice = 0;
        _borrowPeriod.totalBorrowed = _borrowPeriod.totalBorrowed.sub(_borrowAccount.borrowed);
        _borrowPeriod.borrowed[_msgSender()] = _borrowPeriod.borrowed[_msgSender()].sub(_borrowAccount.borrowed);
        _borrowAccount.borrowed = 0;

        emit Repay(_msgSender(), _periodId, _collateral, _borrowed, balAfterRepay);
    }

    /** @dev Amount the user has to repay the protocol */
    function _repayLessEqual(
        address _account, IERC20 _collateral, IERC20 _borrowed,
        uint256 _balAfterRepay, BorrowPeriod storage _borrowPeriod, BorrowAccount storage _borrowAccount
    ) internal {
        uint256 repayAmount = _borrowAccount.collateral.sub(_balAfterRepay);
        _borrowAccount.collateral = _balAfterRepay;

        // Swap the repay value back for the borrowed asset
        uint256 amountOut = _swap(_collateral, _borrowed, repayAmount);

        // Provide a reward to the user who repayed the account if they are not the account owner
        uint256 reward = 0;
        if (_account != _msgSender()) {
            reward = amountOut.mul(compensationPercentage()).div(100);
            _borrowed.safeTransfer(_msgSender(), reward);
        }

        // Return the assets back to the pool
        uint256 depositValue = amountOut.sub(reward);
        _borrowed.safeApprove(address(pool), depositValue);
        pool.deposit(_borrowed, depositValue);
    }

    /** @dev Convert the accounts tokens back to the deposited asset */
    function _repayGreater(
        address _account, IERC20 _collateral, IERC20 _borrowed,
        uint256 _balAfterRepay, BorrowPeriod storage _borrowPeriod, BorrowAccount storage _borrowAccount
    ) internal {
        uint256 payout = oracle.pairPrice(_collateral, _borrowed).mul(_balAfterRepay.sub(_borrowAccount.collateral)).div(oracle.decimals());

        // Get the amount in borrowed assets that the earned balance is worth and swap them for the given asset
        pool.withdraw(_borrowed, payout);
        uint256 amountOut = _swap(_borrowed, _collateral, payout);

        // Provide a reward to the user who repayed the account if they are not the account owner
        _borrowAccount.collateral = _borrowAccount.collateral.add(amountOut);
        if (_account != _msgSender()) {
            uint256 reward = amountOut.mul(compensationPercentage()).div(100);
            _collateral.safeTransfer(_msgSender(), reward);

            _borrowAccount.collateral = _borrowAccount.collateral.sub(reward);
        }
    }

    event Borrow(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 amount);
    event Repay(address indexed account, uint256 indexed periodId, IERC20 collateral, IERC20 borrowed, uint256 balance);
}