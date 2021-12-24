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

    constructor(Oracle oracle_, LPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_) {
        oracle = oracle_;
        pool = pool_;
        minBorrowLength = minBorrowLength_;
        maxInterestPercent = maxInterestPercent_;
        minMarginThreshold = minMarginThreshold_;
    }

    // ======== Getters ========


    // ======== Setters and modifiers ========

    modifier onlyApproved(IERC20 _token) {
        require(pool.isApproved(_token), "This token has not been approved");
        _;
    }

    /** @dev Set the minimum borrow length */
    function setMinBorrowLength(uint256 _minBorrowLength) external onlyOwner {
        minBorrowLength = _minBorrowLength;
    }

    /** @dev Set the maximum interest percent */
    function setMaxInterestPercent(uint256 _maxInterestPercent) external onlyOwner {
        maxInterestPercent = _maxInterestPercent;
    }

    /** @dev Set the minimum margin level */
    function setMinMarginThreshold(uint256 _minMarginThreshold) external onlyOwner {
        minMarginThreshold = _minMarginThreshold;
    }

    /** @dev Set the minimum amount of collateral for a given token required to borrow against */
    function setMinCollateral(IERC20 _token, uint256 _amount) external onlyApproved(_token) onlyOwner {
        MinCollateral[_token] = _amount;
    }

    // ======== Calculation assistances ========


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

}