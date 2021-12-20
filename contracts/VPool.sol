//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Margin.sol";

contract VPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Approved assets of the pool
    IERC20[] private approvedList;
    mapping(IERC20 => bool) private approved;

    // Staking data
    struct StakingPeriod {
        uint256 totalDeposited;
        uint256 liquidity;
        mapping(address => uint256) deposits;
    }
    mapping(uint256 => mapping(IERC20 => StakingPeriod)) private stakingPeriods; // Stores the data for each approved asset
    uint256 public periodLength;
    uint256 public cooldownLength;

    uint256 public taxPercent;

    Margin public margin;

    constructor(uint256 periodLength_, uint256 cooldownLength_, uint256 taxPercent_, Margin margin_) {
        periodLength = periodLength_;
        cooldownLength = cooldownLength_;
        taxPercent = taxPercent_;
        margin = margin_;
    }

    // ======== Contract configuration ========

    /** @dev Set the tax percentage */
    function setTaxPercentage(uint256 _taxPercent) external onlyOwner {
        taxPercent = _taxPercent;
    }

    // ======== Check the staking period and cooldown periods ========

    /** @dev Get the times at which the prologue of the given period occurs */
    function getPrologueTimes(uint256 _periodId) public view returns (uint256, uint256) {
        // Return the times of when the prologue is between
        uint256 prologueStart = _periodId.mul(periodLength);
        uint256 prologueEnd = prologueStart.add(cooldownLength);
        return (prologueStart, prologueEnd);
    }

    /** @dev Checks if the given period is in the prologue phase */
    function isPrologue(uint256 _periodId) public view returns (bool) {
        // Check if the prologue period of the specified period is present
        (uint256 prologueStart, uint256 prologueEnd) = getPrologueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= prologueStart && current < prologueEnd);
    }

    /** @dev Get the times at which the epilogue of the given period occurs */
    function getEpilogueTimes(uint256 _periodId) public view returns (uint256, uint256) {
        // Return the times of when the epilogue is between
        uint256 periodId = _periodId.add(1);
        uint256 epilogueEnd = periodId.mul(periodLength);
        uint256 epilogueStart = epilogueEnd.sub(cooldownLength);
        return (epilogueStart, epilogueEnd);
    }

    /** @dev Checks if the given period is in the epilogue phase */
    function isEpilogue(uint256 _periodId) public view returns (bool) {
        // Check if the epilogue period of the specified period is present
        (uint256 epilogueStart, uint256 epilogueEnd) = getEpilogueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= epilogueStart && current < epilogueEnd);
    }

    /** @dev Checks if the specified period is the current period */
    function isCurrentPeriod(uint256 _periodId) public view returns (bool) {
        return _periodId == currentPeriodId();
    }

    /** @dev Returns the id of the current period */
    function currentPeriodId() public view returns (uint256) {
        return uint256(block.timestamp).div(periodLength);
    }

    // ======== Approved tokens ========

    /** @dev Approves a token for use with the protocol */
    function approveToken(IERC20 _token) external onlyOwner {
        // Satisfy the requirements
        require(!isApproved(_token), "This token has already been approved");

        // Approve the token
        approved[_token] = true;
        approvedList.push(_token);
    }

    /** @dev Returns whether or not a token is approved */
    function isApproved(IERC20 _token) public view returns (bool) {
        return approved[_token];
    }

    /** @dev Returns a list of approved tokens */
    function getApproved() external view returns (IERC20[] memory) {
        return approvedList;
    }

    modifier onlyApproved(IERC20 _token) {
        require(isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Helper functions ========

    /** @dev Returns the total locked liquidity for the current period */
    function getLiquidity(IERC20 _token, uint256 _periodId) external view returns (uint256) {
        return stakingPeriods[_periodId][_token].liquidity;
    }

    // ======== Balance management ========

    /** @dev Returns the deposited balance of a given account for a given token for a given period */
    function balanceOf(address _account, IERC20 _token, uint256 _periodId) public view returns (uint256) {
        // Get the amount of tokens the account deposited into a given period
        return stakingPeriods[_periodId][_token].deposits[_account];
    }

    /** @dev Returns the value of the tokens for a given period for a given token once they are redeemed */
    function redeemValue(IERC20 _token, uint256 _amount, uint256 _periodId) public view onlyApproved(_token) returns (uint256) {
        // Get the value for redeeming a given amount of tokens for a given periodId
        StakingPeriod storage period = stakingPeriods[_periodId][_token];

        uint256 totalDeposited = period.totalDeposited;
        uint256 liquidity = period.liquidity;

        return _amount.mul(liquidity).div(totalDeposited);
    }

    // ======== Liquidity manipulation ========

    /** @dev Stakes a given amount of specified tokens in the pool */
    function stake(IERC20 _token, uint256 _amount, uint256 _periodId) external onlyApproved(_token) {
        // Make sure the requirements are satisfied
        require(_periodId >= currentPeriodId(), "May only stake into current or future periods");
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Staking is only allowed during the prologue period or for a future period");

        // Move the tokens to the pool and update the users deposit amount
        _token.safeTransferFrom(_msgSender(), address(this), _amount);

        StakingPeriod storage stakingPeriod = stakingPeriods[_periodId][_token];

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].add(_amount);
        stakingPeriod.liquidity = stakingPeriod.liquidity.add(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.add(_amount);

        emit Stake(_msgSender(), _periodId, _token, _amount);
    }

    /** @dev Redeems the staked amount of tokens in a given pool */
    function redeem(IERC20 _token, uint256 _amount, uint256 _periodId) external {
        // Make sure the requirements are satisfied
        require(isPrologue(_periodId) || !isCurrentPeriod(_periodId), "Redeem is only allowed during prologue period or once period has ended");
        require(_amount <= balanceOf(_msgSender(), _token, _periodId), "Cannot redeem more than total balance");

        // Update the balances of the period
        StakingPeriod storage stakingPeriod = stakingPeriods[_periodId][_token];

        // Withdraw the allocated amount from the pool and return it to the user
        uint256 tokensRedeemed = redeemValue(_token, _amount, _periodId);

        stakingPeriod.deposits[_msgSender()] = stakingPeriod.deposits[_msgSender()].sub(_amount);
        stakingPeriod.totalDeposited = stakingPeriod.totalDeposited.sub(_amount);

        stakingPeriod.liquidity = stakingPeriod.liquidity.sub(tokensRedeemed);
        _token.safeTransfer(_msgSender(), tokensRedeemed);

        emit Redeem(_msgSender(), _periodId, _token, _amount, tokensRedeemed);
    }

    /** @dev Deposit tokens into the pool and increase the liquidity of the pool */
    function deposit(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        // Make sure no deposits during cooldown period
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot deposit during prologue");

        // Pay a tax to the owner
        uint256 amount = _amount;
        {
            uint256 tax = _amount.mul(taxPercent).div(100);
            amount = amount.sub(tax);
            _token.safeTransferFrom(_msgSender(), owner(), tax);
        }

        // Receive a given number of funds to the current pool
        _token.safeTransferFrom(_msgSender(), address(this), amount);
        stakingPeriods[periodId][_token].liquidity = stakingPeriods[periodId][_token].liquidity.add(amount);
        emit Deposit(_msgSender(), periodId, _token, amount);
    }

    /** @dev Withdraw tokens from the pool and decrease the liquidity of the pool */
    function withdraw(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        // Only margin may call this and make sure no withdraws during cooldown period
        require(_msgSender() == address(margin), "Only the margin may call this function");
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot withdraw during prologue");

        // Withdraw an amount from the current pool
        StakingPeriod storage stakingPeriod = stakingPeriods[periodId][_token]; 
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