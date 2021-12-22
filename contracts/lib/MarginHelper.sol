//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Oracle.sol";
import "../LPool.sol";

abstract contract MarginHelper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    Oracle public immutable oracle;
    LPool public immutable pool;

    struct BorrowAccount {
        uint256 collateral;
        uint256 borrowed;
        uint256 initialPrice;
        uint256 borrowTime;
        uint256 initialBorrowTime;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(IERC20 => BorrowAccount)) collateral; // account => token => borrow - the same account can have different borrows with different collaterals independently
        mapping(address => uint256) borrowed;
    }

    mapping(IERC20 => uint256) private MinCollateral;

    uint256 public minBorrowLength;
    uint256 public minMarginThreshold; // Stored as the percentage above equilibrium threshold

    uint256 public maxInterestPercent;

    constructor(Oracle oracle_, LPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_) {
        oracle = oracle_;
        pool = pool_;
        minBorrowLength = minBorrowLength_;
        maxInterestPercent = maxInterestPercent_;
        minMarginThreshold = minMarginThreshold_;
    }

    // ======== Getters ========

    /** @dev Gets the minimum amount of collateral required to borrow a token */
    function minCollateral(IERC20 _token) public view returns (uint256) {
        return MinCollateral[_token];
    }

    /** @dev Get the percentage rewarded to a user who performed an autonomous operation */
    function compensationPercentage() public view virtual returns (uint256);

    /** @dev Calculate the interest at the current time for a given asset from the amount initially borrowed */
    function calculateInterest(IERC20 _borrowed, uint256 _initialBorrow, uint256 _borrowTime) public view virtual returns (uint256);

    // ======== Setters and modifiers ========

    modifier onlyApproved(IERC20 _token) {
        require(pool.isApproved(_token), "This token has not been approved");
        _;
    }

    /** @dev Set the minimum borrow length */
    function setMinBorrowLength(uint256 _minBorrowLength) external onlyOwner { minBorrowLength = _minBorrowLength; } 

    /** @dev Set the maximum interest percent */
    function setMaxInterestPercent(uint256 _maxInterestPercent) external onlyOwner { maxInterestPercent = _maxInterestPercent; }

    /** @dev Set the minimum margin level */
    function setMinMarginThreshold(uint256 _minMarginThreshold) external onlyOwner { minMarginThreshold = _minMarginThreshold; }

    /** @dev Set the minimum amount of collateral for a given token required to borrow against */
    function setMinCollateral(IERC20 _token, uint256 _amount) external onlyApproved(_token) onlyOwner {
        MinCollateral[_token] = _amount;
    }

    // ======== Calculation assistances ========

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

    // ======== Utils ========

    function _swap(IERC20 _token1, IERC20 _token2, uint256 _amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        address router = address(oracle.router());
        _token1.safeApprove(address(router), _amount);
        return UniswapV2Router02(router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 1 hours)[1];
    }

    // ======== Core helpers ========

    /** @dev Require that the borrow is not instantly liquidatable and update the balances */
    function _borrow(BorrowAccount storage _borrowAccount, BorrowPeriod storage _borrowPeriod, IERC20 _collateral, IERC20 _borrowed, uint256 _amount) internal {
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

    /** @dev Get the interest and borrowed current price to help the balance function */
    function _balanceOf(IERC20 _collateral, IERC20 _borrowed, BorrowAccount memory _borrowAccount) internal view returns (uint256, uint256) {
        uint256 interest = calculateInterest(_borrowed, _borrowAccount.initialPrice, _borrowAccount.initialBorrowTime);
        uint256 borrowedCurrentPrice = oracle.pairPrice(_borrowed, _collateral).mul(_borrowAccount.borrowed).div(oracle.decimals());
        return (interest, borrowedCurrentPrice);
    }

    /** @dev Convert the accounts tokens back to the deposited asset */
    function _repayGreater(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _balAfterRepay, BorrowAccount storage _borrowAccount) internal {
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

    /** @dev Amount the user has to repay the protocol */
    function _repayLessEqual(address _account, IERC20 _collateral, IERC20 _borrowed, uint256 _balAfterRepay, BorrowAccount storage _borrowAccount) internal {
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
}