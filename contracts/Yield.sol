//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPool.sol";
import "./Margin.sol";
import "./Oracle.sol";
import "./IYield.sol";

contract YieldApproved is Ownable, IYield {
    using SafeMath for uint256;

    LPool public immutable pool;
    Margin public immutable margin;
    Oracle public immutable oracle;
    IERC20 public immutable token;

    mapping(uint256 => mapping(address => bool)) private Yields; // Period id => account => has yielded

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

    /** @dev Calculate the yield for the given account and update their yield status */
    function yield(address _account) external override returns (uint256) {
        uint256 periodId = pool.currentPeriodId();
        require(_msgSender() == address(token), "Only the token may call yield");
        require(!pool.isPrologue(periodId), "Cannot approve yield during prologue phase");
        require(!Yields[periodId][_account], "Yield has already been claimed");

        uint256 totalYield = 0;

        IERC20[] memory assets = pool.approvedList();
        for (uint256 i = 0; i < assets.length; i++) {
            IERC20 _token = assets[i];

            uint256 interestRate = margin.calculateInterestRate(_token).mul(pool.periodLength());
            uint256 utilizationRate = interestRate.mul(100).div(margin.maxInterestPercent()); // **** How does this work + add to margin ??? - remove the for loop and do it for a single token

            uint256 staked = pool.balanceOf(_account, _token, periodId);
            uint256 borrowed = margin.debtOf(_account, _token);

            uint256 stakedReward = staked.mul(interestRate.mul(utilizationRate)).div(oracle.decimals().mul(oracle.decimals()));
            uint256 borrowedReward = borrowed.mul(interestRate).div(oracle.decimals());

            totalYield = totalYield.add(stakedReward).add(borrowedReward);
        }

        Yields[periodId][_account] = true;
        return totalYield;
    }
}