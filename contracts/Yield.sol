//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPool.sol";
import "./Margin.sol";
import "./IYield.sol";

contract YieldApproved is Ownable, IYield {
    using SafeMath for uint256;

    LPool public immutable pool;
    Margin public immutable margin;
    IERC20 public immutable token;

    struct Yield {
        uint256 stake;
        uint256 borrow;
    }
    mapping(uint256 => mapping(address => mapping(IERC20 => Yield))) private Yields; // Period id => account => token => stake

    mapping(IERC20 => uint256) private NumYields;
    uint256 public slashingRate;

    constructor(LPool pool_, Margin margin_, IERC20 token_, uint256 slashingRate_) {
        pool = pool_; 
        margin = margin_;
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

        // Go through and calculate the yield for all of the users tokens
        // **** Maybe add an interface to check the amount of the asset borrowed ?

        Yield storage _yield = Yields[periodId][_account][_token];

        require(_msgSender() == address(token), "Only the token may call yield");
        require(!pool.isPrologue(periodId), "Cannot approve yield during prologue phase");
        require(yield.stake == 0 || yield.borrow == 0, "Yield has already been approved");

        uint256 stake = 0;
        if (yield.stake == 0) {
            stake = pool.balanceOf(_account, _token, periodId);
            Yields[periodId][_account][_token].stake = stake;
        }

        uint256 borrow = 0;
        if (yield.borrow == 0) {
            IERC20[] memory tokens = pool.approvedList();
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 borrowed = margin.debtOf(_account, tokens[i], _token);
                if (borrowed > borrow) borrow = borrowed;
            }
        }

        return (stake, borrow);
    }
}