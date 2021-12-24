//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Oracle.sol";
import "./LPool.sol";
import "./lib/UniswapV2Router02.sol";
import "./lib/MarginCore.sol";

contract Margin is Ownable, MarginCore {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) private BorrowPeriods;

    constructor(Oracle oracle_, LPool pool_, uint256 minBorrowLength_, uint256 maxInterestPercent_, uint256 minMarginThreshold_)
        MarginCore(oracle_, pool_, minBorrowLength_, maxInterestPercent_, minMarginThreshold_)
    {}

    // ======== Getters ========


    // ======== Deposit and withdraw ========


    // ======== Borrow ========


    // **** I think I would like a number of the total collateral borrowed too just to be difficult

    // ======== Repay and withdraw ========

    // ======== Liquidate ========


    // ======== Events ========
}