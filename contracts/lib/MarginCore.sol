//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Oracle.sol";
import "../LPool.sol";

abstract contract MarginCore is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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
    }

    Oracle public immutable oracle;
    LPool public immutable pool;

    uint256 public minBorrowLength;
    uint256 public minMarginThreshold; // Stored as the percentage above equilibrium threshold

    uint256 public maxInterestPercent;

    mapping(IERC20 => uint256) private MinCollateral;

    constructor(Oracle oracle_, LPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_) {
        oracle = oracle_;
        pool = pool_;
        minBorrowLength = minBorrowLength_;
        maxInterestPercent = maxInterestPercent_;
        minMarginThreshold = minMarginThreshold_;
    }

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

    // ======== Getters ========

    /** @dev Gets the minimum amount of collateral required to borrow a token */
    function minCollateral(IERC20 _token) public view returns (uint256) {
        return MinCollateral[_token];
    }

    /** @dev Get the percentage rewarded to a user who performed an autonomous operation */
    function compensationPercentage() public view returns (uint256) {
        return minMarginThreshold.mul(100).div(minMarginThreshold.add(100)).div(10);
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
}