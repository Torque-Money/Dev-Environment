//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPool.sol";
import "./Margin.sol";
import "./Oracle.sol";
import "./lib/IYield.sol";

contract YieldApproved is Ownable, IYield {
    using SafeMath for uint256;

    LPool public immutable pool;
    Margin public immutable margin;
    Oracle public immutable oracle;
    IERC20 public immutable token;

    mapping(uint256 => mapping(address => mapping(IERC20 => bool))) private Yields; // Period id => account => token => has yielded

    mapping(IERC20 => uint256) private NumYields;
    uint256 public slashingRate;

    constructor(LPool pool_, Margin margin_, Oracle oracle_, IERC20 token_, uint256 slashingRate_) {
        pool = pool_; 
        margin = margin_;
        oracle = oracle_;
        token = token_;
        slashingRate = slashingRate_;
    }

    /** @dev Set the slashing rate of the protocol */
    function setSlashingRate(uint256 _slashingRate) external onlyOwner {
        slashingRate = _slashingRate;
    }

    /** @dev Calculate the yield for the given account and token and update their yield status */
    function yield(address _account, IERC20 _token) external override returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        require(pool.isApproved(_token), "This token has not been approved");
        require(_msgSender() == address(token), "Only the token may call yield");
        require(!pool.isPrologue(periodId), "Cannot claim yield during prologue");
        require(!Yields[periodId][_account][_token], "Yield has already been claimed for this token");

        uint256 interestRate = margin.interestRate(_token).mul(pool.periodLength());
        uint256 utilizationRate = margin.utilizationRate(_token);

        uint256 staked = pool.balanceOf(_account, _token, periodId);
        uint256 borrowed = margin.debtOf(_account, _token);

        uint256 stakedReward = staked.mul(interestRate.mul(utilizationRate)).div(oracle.decimals().mul(oracle.decimals()));
        uint256 borrowedReward = borrowed.mul(interestRate).div(oracle.decimals());

        uint256 slash = NumYields[_token].mul(slashingRate).div(100);
        if (slash == 0) slash = 1;
        uint256 totalYield = stakedReward.add(borrowedReward).div(slash);

        Yields[periodId][_account][_token] = true;
        NumYields[_token] = NumYields[_token].add(1);
        return totalYield;
    }
}