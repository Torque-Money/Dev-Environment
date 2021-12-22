//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/LPoolCore.sol";
import "./Margin.sol";

contract LPool is LPoolCore {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(uint256 => mapping(IERC20 => StakingPeriod)) private StakingPeriods; // Period Id => token => staking period

    uint256 public taxPercent;
    address public taxAccount;

    constructor(uint256 periodLength_, uint256 cooldownLength_, uint256 taxPercent_) LPoolCore(periodLength_, cooldownLength_) {
        taxPercent = taxPercent_;
        taxAccount = _msgSender();
    }

    // ======== Admin ========

    /** @dev Set the tax percentage */
    function setTaxPercentage(uint256 _taxPercent) external onlyOwner {
        taxPercent = _taxPercent;
    }

    /** @dev Set the tax account */
    function setTaxAccount(address _account) external onlyOwner {
        taxAccount = _account;
    }

    // ======== Balance management ========

    /** @dev Returns the deposited balance of a given account for a given token for a given period */
    function balanceOf(address _account, IERC20 _token, uint256 _periodId) public view returns (uint256) {
        return StakingPeriods[_periodId][_token].deposits[_account];
    }

    /** @dev Returns the value of the tokens for a given period for a given token once they are redeemed */
    function redeemValue(IERC20 _token, uint256 _amount, uint256 _periodId) public view onlyApproved(_token) returns (uint256) {
        StakingPeriod storage period = StakingPeriods[_periodId][_token];
        return _amount.mul(period.liquidity).div(period.totalDeposited);
    }

    // ======== Liquidity manipulation ========

    /** @dev Returns the total locked liquidity for the current period */
    function liquidity(IERC20 _token, uint256 _periodId) external view returns (uint256) {
        return StakingPeriods[_periodId][_token].liquidity;
    }

    /** @dev Stakes a given amount of specified tokens in the pool */
    function stake(IERC20 _token, uint256 _amount, uint256 _periodId) external onlyApproved(_token) {
        require(_periodId >= currentPeriodId(), "May only stake into current or future periods");
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Staking is only allowed during the prologue period or for a future period");

        // Move the tokens to the pool and update the users deposit amount
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(_amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(_amount);

        emit Stake(_msgSender(), _periodId, _token, _amount);
    }

    /** @dev Redeems the staked amount of tokens in a given pool */
    function redeem(IERC20 _token, uint256 _amount, uint256 _periodId) external {
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Redeem is only allowed during prologue period or once period has ended");
        require(_amount <= balanceOf(_msgSender(), _token, _periodId), "Cannot redeem more than total balance");

        // Update the balances of the period, withdraw collateral and return to user
        StakingPeriod storage stakingPeriod = StakingPeriods[_periodId][_token];

        uint256 tokensRedeemed = redeemValue(_token, _amount, _periodId);

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].sub(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.sub(_amount);

        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(tokensRedeemed);
        _token.safeTransfer(_msgSender(), tokensRedeemed);

        emit Redeem(_msgSender(), _periodId, _token, _amount, tokensRedeemed);
    }

    /** @dev Allow an approved user to claim collateral as their own */
    function claim(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        // **** Might need a seperate struct for this for the approved users
    }

    /** @dev Allow an approved user to unclaim collateral as their own */
    function unclaim(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
    }

    /** @dev Deposit tokens into the pool and increase the liquidity of the pool */
    function deposit(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot deposit during prologue");

        // Pay a tax to the contract owner
        uint256 amount = _amount;
        {
            uint256 tax = _amount.mul(taxPercent).div(100);
            amount = amount.sub(tax);
            _token.safeTransferFrom(_msgSender(), taxAccount, tax);
        }

        // Deposit the funds to the current pool
        _token.safeTransferFrom(_msgSender(), address(this), amount);
        StakingPeriods[periodId][_token].liquidity = StakingPeriods[periodId][_token].liquidity.add(amount);

        emit Deposit(_msgSender(), periodId, _token, amount);
    }

    /** @dev Withdraw tokens from the pool and decrease the liquidity of the pool */
    function withdraw(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(_msgSender() == address(margin), "Only the margin may call this function"); // **** This needs to be removed and swapped with the approved owners - I need to set that up properly
        require(!isPrologue(periodId), "Cannot withdraw during prologue");

        // Withdraw an amount from the current pool
        StakingPeriod storage stakingPeriod = StakingPeriods[periodId][_token]; 

        require(_amount <= stakingPeriod.liquidity, "Cannot withdraw more than value pool");

        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(_amount);
        _token.safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), periodId, _token, _amount);
    }

    // ======== Events ========

    event Stake(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Redeem(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount, uint256 liquidity);

    event Deposit(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed periodId, IERC20 token, uint256 amount);
}