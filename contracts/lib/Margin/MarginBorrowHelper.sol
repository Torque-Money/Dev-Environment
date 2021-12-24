//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginCore.sol";

abstract contract MarginBorrowHelper is MarginCore {
    using SafeMath for uint256;

    uint256 public minBorrowLength;
    mapping(IERC20 => uint256) private MinCollateral;

    constructor(uint256 minBorrowLength_) {
        minBorrowLength = minBorrowLength_;
    }

    /** @dev Set the minimum borrow length */
    function setMinBorrowLength(uint256 _minBorrowLength) external onlyOwner {
        minBorrowLength = _minBorrowLength;
    }

    /** @dev Set the minimum amount of collateral for a given token required to borrow against */
    function setMinCollateral(IERC20 _token, uint256 _amount) external onlyApproved(_token) onlyOwner {
        MinCollateral[_token] = _amount;
    }

    /** @dev Return the minimum borrow time remaining */
    function minBorrowTimeRemaining(address _account, IERC20 _collateral, IERC20 _borrowed) external view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        BorrowAccount storage borrowAccount = BorrowPeriods[periodId][_borrowed].collateral[_account][_collateral];
        return borrowAccount.borrowTime.add(minBorrowLength).sub(block.timestamp);
    }

    /** @dev Gets the minimum amount of collateral required to borrow a token */
    function minCollateral(IERC20 _token) public view returns (uint256) {
        return MinCollateral[_token];
    }

    /** @dev Return the total amount of a given asset borrowed */
    function borrowed(IERC20 _token) public view returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        return BorrowPeriods[periodId][_token].totalBorrowed;
    }
}