//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginCore.sol";

abstract contract MarginLiquidate is MarginCore {
    using SafeMath for uint256;

    /** @dev Check if an account is liquidatable */
    function isLiquidatable(address _account, IERC20 _collateral, IERC20 _borrowed) public view returns (bool) {
        return marginLevel(_account, _collateral, _borrowed) < _minMarginLevel();
    }

    /** @dev Liquidates a users account that is liquidatable / below the minimum margin level */
    function flashLiquidate(address _account, IERC20 _collateral, IERC20 _borrowed) external onlyApproved(_collateral) onlyApproved(_borrowed) {
        require(isLiquidatable(_account, _borrowed, _collateral), "This account is not liquidatable");

        uint256 periodId = pool.currentPeriodId();
        BorrowPeriod storage borrowPeriod = BorrowPeriods[periodId][_borrowed];
        BorrowAccount storage borrowAccount = borrowPeriod.collateral[_account][_collateral];

        // Swap the users collateral for assets
        uint256 amountOut = _swap(_collateral, _borrowed, borrowAccount.collateral);

        // Compensate the liquidator
        uint256 reward = amountOut.mul(compensationPercentage()).div(100);
        _borrowed.safeTransfer(_msgSender(), reward);
        uint256 depositValue = amountOut.sub(reward);
        _borrowed.safeApprove(address(pool), depositValue);
        pool.deposit(_borrowed, depositValue);

        // Update the users account
        borrowAccount.collateral = 0;
        borrowPeriod.totalBorrowed = borrowPeriod.totalBorrowed.sub(borrowAccount.borrowed);
        borrowAccount.borrowed = 0;
        borrowAccount.initialPrice = 0;

        emit FlashLiquidation(_account, periodId, _msgSender(), _collateral, _borrowed, borrowAccount.collateral);

        event FlashLiquidation(address indexed account, uint256 indexed periodId, address liquidator, IERC20 collateral, IERC20 borrowed, uint256 amount);
    }

    /** @dev Get the percentage rewarded to a user who performed an autonomous operation */
    function compensationPercentage() public view override returns (uint256) {
        return minMarginThreshold.mul(100).div(minMarginThreshold.add(100)).div(10);
    }
}