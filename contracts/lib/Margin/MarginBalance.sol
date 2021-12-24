//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract MarginBalance {
    /** @dev Get the collateral of an account for a given pool and period id */
    function collateralOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) external view returns (uint256) {
        BorrowPeriod storage borrowPeriod = BorrowPeriods[_periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        return borrowAccount.collateral;
    }

    /** @dev Get the debt of a given account */
    function debtOf(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.borrowed;
    }

    /** @dev Return the total debt of a given asset for a given account */
    function debtOf(address _account, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        return borrowPeriod.borrowed[_account];
    }

    /** @dev Check the current margin balance of an account */
    function balanceOf(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _periodId) public view returns (uint256) {
        BorrowAccount storage borrowAccount = BorrowPeriods[_periodId][_borrowed].collateral[_account][_collateral];

        (uint256 interest, uint256 borrowedCurrentPrice) = _balanceOfHelper(_collateral, _borrowed, borrowAccount);
        if (!pool.isCurrentPeriod(_periodId)) return borrowAccount.collateral.sub(interest);

        return borrowAccount.collateral.add(borrowedCurrentPrice).sub(borrowAccount.initialPrice).sub(interest);
    }

    /** @dev Get the interest and borrowed current price to help the balance function */
    function _balanceOfHelper(IERC20 _collateral, IERC20 _borrowed, BorrowAccount memory _borrowAccount) internal view returns (uint256, uint256) {
        uint256 interest = calculateInterest(_borrowed, _borrowAccount.initialPrice, _borrowAccount.initialBorrowTime);
        uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral).mul(_borrowAccount.borrowed).div(oracle.decimals());
        return (interest, borrowedCurrentPrice);
    }
}