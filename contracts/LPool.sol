//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Margin.sol";

contract LPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    Margin public immutable margin;

    IERC20[] private ApprovedList;
    mapping(IERC20 => bool) private Approved; // Token => approved

    struct StakingPeriod {
        uint256 totalDeposited;
        uint256 liquidity;
        mapping(address => uint256) deposits;
    }
    mapping(uint256 => mapping(IERC20 => StakingPeriod)) private StakingPeriods; // Period Id => token => staking period
    uint256 public immutable periodLength;
    uint256 public immutable cooldownLength;

    uint256 public taxPercent;

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
    function prologueTimes(uint256 _periodId) public view returns (uint256, uint256) {
        uint256 prologueStart = _periodId.mul(periodLength);
        uint256 prologueEnd = prologueStart.add(cooldownLength);
        return (prologueStart, prologueEnd);
    }

    /** @dev Checks if the given period is in the prologue phase */
    function isPrologue(uint256 _periodId) public view returns (bool) {
        (uint256 prologueStart, uint256 prologueEnd) = prologueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= prologueStart && current < prologueEnd);
    }

    /** @dev Get the times at which the epilogue of the given period occurs */
    function epilogueTimes(uint256 _periodId) public view returns (uint256, uint256) {
        uint256 periodId = _periodId.add(1);
        uint256 epilogueEnd = periodId.mul(periodLength);
        uint256 epilogueStart = epilogueEnd.sub(cooldownLength);
        return (epilogueStart, epilogueEnd);
    }

    /** @dev Checks if the given period is in the epilogue phase */
    function isEpilogue(uint256 _periodId) public view returns (bool) {
        (uint256 epilogueStart, uint256 epilogueEnd) = epilogueTimes(_periodId);

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
        require(!isApproved(_token), "This token has already been approved");

        Approved[_token] = true;
        ApprovedList.push(_token);
    }

    function approvedList() external view returns (IERC20[] memory) {
        return ApprovedList;
    }

    /** @dev Returns whether or not a token is approved */
    function isApproved(IERC20 _token) public view returns (bool) {
        return Approved[_token];
    }

    modifier onlyApproved(IERC20 _token) {
        require(isApproved(_token), "This token has not been approved");
        _;
    }

    // ======== Helper functions ========

    /** @dev Returns the total locked liquidity for the current period */
    function liquidity(IERC20 _token, uint256 _periodId) external view returns (uint256) {
        return StakingPeriods[_periodId][_token].liquidity;
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

    /** @dev Deposit tokens into the pool and increase the liquidity of the pool */
    function deposit(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(!isPrologue(periodId), "Cannot deposit during prologue");

        // Pay a tax to the contract owner
        uint256 amount = _amount;
        {
            uint256 tax = _amount.mul(taxPercent).div(100);
            amount = amount.sub(tax);
            _token.safeTransferFrom(_msgSender(), owner(), tax);
        }

        // Deposit the funds to the current pool
        _token.safeTransferFrom(_msgSender(), address(this), amount);
        StakingPeriods[periodId][_token].liquidity = StakingPeriods[periodId][_token].liquidity.add(amount);
        
        emit Deposit(_msgSender(), periodId, _token, amount);
    }

    /** @dev Withdraw tokens from the pool and decrease the liquidity of the pool */
    function withdraw(IERC20 _token, uint256 _amount) external onlyApproved(_token) {
        uint256 periodId = currentPeriodId();
        require(_msgSender() == address(margin), "Only the margin may call this function");
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