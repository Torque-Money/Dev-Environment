//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract MarginLevel {
    /** @dev Get the margin level of the given account */
    function marginLevel(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (uint256) {
        BorrowAccount storage borrowAccount = BorrowPeriods[pool.currentPeriodId()][_borrowed].collateral[_account][_collateral];
        uint256 interest = calculateInterest(_borrowed, borrowAccount.initialPrice, borrowAccount.initialBorrowTime);
        return _marginLevel(borrowAccount.collateral, borrowAccount.initialPrice, borrowAccount.borrowed, _collateral, _borrowed, interest);
    }

    /** @dev Calculate the margin level */
    function _calculateMarginLevel(uint256 _deposited, uint256 _currentBorrowPrice, uint256 _initialBorrowPrice, uint256 _interest) internal view returns (uint256) {
        uint256 retValue;
        { retValue = oracle.decimals(); }
        { retValue = retValue.mul(_deposited.add(_currentBorrowPrice)); }
        { retValue = retValue.div(_initialBorrowPrice.add(_interest)); }
        
        return retValue;
    }

    /** @dev Calculate the margin level from the given requirements - returns the value multiplied by decimals */
    function _marginLevel(
        uint256 _deposited, uint256 _initialBorrowPrice, uint256 _amountBorrowed,
        IERC20 _collateral, IERC20 _borrowed, uint256 _interest
    ) internal view returns (uint256) {
        if (_amountBorrowed == 0) return oracle.decimals().mul(999);

        uint256 currentBorrowPrice;
        { currentBorrowPrice = oracle.pairPrice(_borrowed, _collateral).mul(_amountBorrowed).div(oracle.decimals()); }
        
        return _calculateMarginLevel(_deposited, currentBorrowPrice, _initialBorrowPrice, _interest);
    }

    /** @dev Return the minimum margin level in terms of decimals */
    function _minMarginLevel() internal view returns (uint256) {
        return minMarginThreshold.add(100).mul(oracle.decimals()).div(100);
    }
}